<?php
/**
 * Plugin Name: Perfect Survey
 * Plugin URI:  https://example.com/perfect-survey
 * Description: Create beautiful surveys and polls for your WordPress site.
 * Version:     1.5.1
 * Author:      WebFactory Ltd
 * License:     GPL2
 * Text Domain: perfect-survey
 */

defined('ABSPATH') or die('No script kiddies please!');

define('PERFECT_SURVEY_VERSION', '1.5.1');
define('PERFECT_SURVEY_DIR', plugin_dir_path(__FILE__));
define('PERFECT_SURVEY_URL', plugin_dir_url(__FILE__));

/* ══════════════════════════════════════════════
   ACTIVATION — create tables
══════════════════════════════════════════════ */
register_activation_hook(__FILE__, 'ps_activate');
function ps_activate() {
    global $wpdb;
    $charset = $wpdb->get_charset_collate();

    $surveys_sql = "CREATE TABLE IF NOT EXISTS {$wpdb->prefix}perfectsurvey_surveys (
        id            BIGINT(20) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        survey_name   VARCHAR(255) NOT NULL,
        survey_description TEXT,
        created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
        status        VARCHAR(20) DEFAULT 'active'
    ) $charset;";

    $questions_sql = "CREATE TABLE IF NOT EXISTS {$wpdb->prefix}perfectsurvey_questions (
        id            BIGINT(20) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        survey_id     BIGINT(20) UNSIGNED NOT NULL,
        question_text TEXT NOT NULL,
        question_type VARCHAR(50) DEFAULT 'radio',
        options       TEXT,
        sort_order    INT DEFAULT 0
    ) $charset;";

    $answers_sql = "CREATE TABLE IF NOT EXISTS {$wpdb->prefix}perfectsurvey_answers (
        id          BIGINT(20) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        survey_id   BIGINT(20) UNSIGNED NOT NULL,
        question_id BIGINT(20) UNSIGNED NOT NULL,
        answer_text TEXT,
        submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        voter_ip    VARCHAR(45)
    ) $charset;";

    require_once ABSPATH . 'wp-admin/includes/upgrade.php';
    dbDelta($surveys_sql);
    dbDelta($questions_sql);
    dbDelta($answers_sql);
}

/* ══════════════════════════════════════════════
   AJAX — VULNERABLE ENDPOINT (Unauthenticated SQLi)
   CVE-equivalent: Perfect Survey < 1.5.2
   The `surveyId` parameter is passed directly
   into a raw SQL query without sanitisation.
══════════════════════════════════════════════ */
add_action('wp_ajax_nopriv_ps_get_survey_results', 'ps_get_survey_results');
add_action('wp_ajax_ps_get_survey_results',        'ps_get_survey_results');
function ps_get_survey_results() {
    global $wpdb;

    // ⚠️  VULNERABLE: no sanitisation on $surveyId
    $surveyId = $_GET['surveyId'];   // intentionally raw

    // Raw query — SQLi here
    $query   = "SELECT * FROM {$wpdb->prefix}perfectsurvey_surveys WHERE id = $surveyId";
    $results = $wpdb->get_results($query);

    wp_send_json_success($results);
}

/* ══════════════════════════════════════════════
   AJAX — VULNERABLE ENDPOINT 2
   Used by the shortcode frontend JS
══════════════════════════════════════════════ */
add_action('wp_ajax_nopriv_ps_load_survey',  'ps_load_survey_ajax');
add_action('wp_ajax_ps_load_survey',         'ps_load_survey_ajax');
function ps_load_survey_ajax() {
    global $wpdb;

    // ⚠️  VULNERABLE: no sanitisation
    $id = $_REQUEST['survey_id'];
    $sql = "SELECT s.*, q.id as qid, q.question_text, q.question_type, q.options, q.sort_order
            FROM {$wpdb->prefix}perfectsurvey_surveys s
            LEFT JOIN {$wpdb->prefix}perfectsurvey_questions q ON q.survey_id = s.id
            WHERE s.id = $id
            ORDER BY q.sort_order ASC";

    $rows = $wpdb->get_results($sql);
    wp_send_json_success($rows);
}

/* ══════════════════════════════════════════════
   AJAX — Submit answer (safe, uses prepare)
══════════════════════════════════════════════ */
add_action('wp_ajax_nopriv_ps_submit_answer', 'ps_submit_answer');
add_action('wp_ajax_ps_submit_answer',        'ps_submit_answer');
function ps_submit_answer() {
    global $wpdb;

    $survey_id   = intval($_POST['survey_id']);
    $question_id = intval($_POST['question_id']);
    $answer      = sanitize_text_field($_POST['answer']);

    $wpdb->insert(
        "{$wpdb->prefix}perfectsurvey_answers",
        [
            'survey_id'   => $survey_id,
            'question_id' => $question_id,
            'answer_text' => $answer,
            'voter_ip'    => $_SERVER['REMOTE_ADDR'],
        ],
        ['%d', '%d', '%s', '%s']
    );

    wp_send_json_success(['message' => 'Cảm ơn bạn đã tham gia khảo sát!']);
}

/* ══════════════════════════════════════════════
   SHORTCODE [ps-survey surveyId='N']
══════════════════════════════════════════════ */
add_shortcode('ps-survey', 'ps_render_survey_shortcode');
function ps_render_survey_shortcode($atts) {
    $atts = shortcode_atts(['surveyid' => 0], $atts, 'ps-survey');
    $id   = intval($atts['surveyid']);
    if (!$id) return '<p>Vui lòng chỉ định ID khảo sát.</p>';

    wp_enqueue_script('ps-frontend', PERFECT_SURVEY_URL . 'assets/js/frontend.js', ['jquery'], PERFECT_SURVEY_VERSION, true);
    wp_enqueue_style('ps-frontend', PERFECT_SURVEY_URL . 'assets/css/frontend.css', [], PERFECT_SURVEY_VERSION);
    wp_localize_script('ps-frontend', 'PS_AJAX', [
        'ajax_url'  => admin_url('admin-ajax.php'),
        'survey_id' => $id,
        'nonce'     => wp_create_nonce('ps_nonce'),
    ]);

    ob_start();
    ?>
    <div id="ps-survey-wrap" data-survey="<?php echo esc_attr($id); ?>">
        <div id="ps-loading" style="text-align:center;padding:2rem;">
            <span class="ps-spinner"></span> Đang tải khảo sát...
        </div>
        <div id="ps-content" style="display:none;"></div>
        <div id="ps-success" style="display:none;text-align:center;padding:2rem;">
            <h3 style="color:#2C1810;">✅ Cảm ơn bạn đã tham gia!</h3>
            <p>Ý kiến của bạn sẽ giúp chúng tôi cải thiện dịch vụ.</p>
        </div>
    </div>
    <?php
    return ob_get_clean();
}

/* ══════════════════════════════════════════════
   ADMIN MENU
══════════════════════════════════════════════ */
add_action('admin_menu', 'ps_admin_menu');
function ps_admin_menu() {
    add_menu_page(
        'Perfect Survey',
        'Perfect Survey',
        'manage_options',
        'perfect-survey',
        'ps_admin_page',
        'dashicons-feedback',
        58
    );
}

function ps_admin_page() {
    global $wpdb;
    $surveys = $wpdb->get_results("SELECT * FROM {$wpdb->prefix}perfectsurvey_surveys ORDER BY created_at DESC");
    ?>
    <div class="wrap">
        <h1>Perfect Survey <span class="ps-version">v<?php echo PERFECT_SURVEY_VERSION; ?></span></h1>
        <p style="color:#c00;">⚠️ Phiên bản này (<?php echo PERFECT_SURVEY_VERSION; ?>) có lỗ hổng bảo mật. Vui lòng cập nhật lên 1.5.2+</p>
        <h2>Danh sách khảo sát</h2>
        <table class="wp-list-table widefat fixed striped">
            <thead><tr>
                <th>ID</th><th>Tên khảo sát</th><th>Mô tả</th><th>Trạng thái</th><th>Ngày tạo</th>
            </tr></thead>
            <tbody>
            <?php foreach ($surveys as $s): ?>
                <tr>
                    <td><?php echo esc_html($s->id); ?></td>
                    <td><?php echo esc_html($s->survey_name); ?></td>
                    <td><?php echo esc_html($s->survey_description); ?></td>
                    <td><?php echo esc_html($s->status); ?></td>
                    <td><?php echo esc_html($s->created_at); ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
        <h2 style="margin-top:2rem;">Sử dụng shortcode</h2>
        <code>[ps-survey surveyId='1']</code>
        <p>Thay số ID tương ứng với khảo sát bạn muốn hiển thị.</p>
    </div>
    <style>
        .ps-version { font-size:.7em; background:#fee; color:#c00; padding:2px 8px; border-radius:4px; vertical-align:middle; }
    </style>
    <?php
}

/* ══════════════════════════════════════════════
   ENQUEUE admin assets
══════════════════════════════════════════════ */
add_action('admin_enqueue_scripts', 'ps_admin_assets');
function ps_admin_assets($hook) {
    if (strpos($hook, 'perfect-survey') === false) return;
    wp_enqueue_style('ps-admin', PERFECT_SURVEY_URL . 'assets/css/admin.css', [], PERFECT_SURVEY_VERSION);
}
