#!/bin/bash
set -e

WP="wp --allow-root --path=/var/www/html"
SETUP_FLAG=/var/www/html/.ipmac_setup_done

if [ -f "$SETUP_FLAG" ]; then
    echo "[IPMAC] Setup already completed, skipping."
    exit 0
fi

echo "[IPMAC] Installing WordPress..."
$WP core install \
    --url="http://cafeipmac.local" \
    --title="IPMAC Café" \
    --admin_user="admin" \
    --admin_password="hulabaloo" \
    --admin_email="admin@cafeipmac.local" \
    --skip-email

echo "[IPMAC] Setting WordPress options..."
$WP option update blogdescription "Nơi Cà Phê Gặp Gỡ Công Nghệ"
$WP option update timezone_string "Asia/Ho_Chi_Minh"
$WP option update date_format "d/m/Y"
$WP option update permalink_structure "/%postname%/"

# Allow admin to install plugins
$WP option update default_role "subscriber"
$WP config set FS_METHOD direct --add

echo "[IPMAC] Installing Astra theme..."
$WP theme install astra --activate || true

echo "[IPMAC] Installing Elementor..."
$WP plugin install elementor --activate || true

echo "[IPMAC] Installing Contact Form 7 (v5.9.8 for WP 6.4 compat)..."
$WP plugin install contact-form-7 --version=5.9.8 --activate || true

echo "[IPMAC] Installing WooCommerce for product catalog..."
$WP plugin install woocommerce --activate || true

echo "[IPMAC] Setting up Perfect Survey (vulnerable)..."
mkdir -p /var/www/html/wp-content/plugins
cp -r /plugins/perfect-survey /var/www/html/wp-content/plugins/
chown -R www-data:www-data /var/www/html/wp-content/plugins/perfect-survey
$WP plugin activate perfect-survey || true

echo "[IPMAC] Installing must-use plugins (fonts + styling)..."
mkdir -p /var/www/html/wp-content/mu-plugins
cp /mu-plugins/ipmac-fonts.php /var/www/html/wp-content/mu-plugins/
chown www-data:www-data /var/www/html/wp-content/mu-plugins/ipmac-fonts.php

echo "[IPMAC] Creating pages..."
# Delete default page
$WP post delete 1 --force 2>/dev/null || true
$WP post delete 2 --force 2>/dev/null || true

# Home page
HOME_ID=$($WP post create \
    --post_title="Trang Chủ" \
    --post_status="publish" \
    --post_type="page" \
    --post_content="$(cat /dev/stdin <<'CONTENT'
<!-- wp:cover {"url":"","dimRatio":40,"style":{"color":{"background":"#2C1810"}}} -->
<div class="wp-block-cover" style="background-color:#2C1810;min-height:500px">
<div class="wp-block-cover__inner-container">
<!-- wp:heading {"textAlign":"center","level":1,"style":{"color":{"text":"#F5ECD7"},"typography":{"fontSize":"3.5rem"}}} -->
<h1 class="has-text-align-center" style="color:#F5ECD7;font-size:3.5rem">☕ IPMAC Café</h1>
<!-- /wp:heading -->
<!-- wp:paragraph {"align":"center","style":{"color":{"text":"#D4A76A"}}} -->
<p class="has-text-align-center" style="color:#D4A76A">Nơi hương cà phê gặp gỡ không gian sáng tạo</p>
<!-- /wp:paragraph -->
<!-- wp:buttons {"layout":{"type":"flex","justifyContent":"center"}} -->
<div class="wp-block-buttons">
<!-- wp:button {"backgroundColor":"luminous-vivid-amber"} -->
<div class="wp-block-button"><a class="wp-block-button__link has-luminous-vivid-amber-background-color has-background wp-element-button" href="/thuc-don">Xem Thực Đơn</a></div>
<!-- /wp:button -->
<!-- wp:button {"className":"is-style-outline"} -->
<div class="wp-block-button is-style-outline"><a class="wp-block-button__link wp-element-button" href="/dat-ban">Đặt Bàn Ngay</a></div>
<!-- /wp:button -->
</div>
<!-- /wp:buttons -->
</div>
</div>
<!-- /wp:cover -->

<!-- wp:columns {"style":{"spacing":{"padding":{"top":"3rem","bottom":"3rem"}}}} -->
<div class="wp-block-columns" style="padding-top:3rem;padding-bottom:3rem">
<!-- wp:column -->
<div class="wp-block-column">
<!-- wp:image {"sizeSlug":"large"} --><figure class="wp-block-image size-large"></figure><!-- /wp:image -->
<!-- wp:heading {"level":3} --><h3 class="wp-block-heading">🌿 Không Gian Xanh</h3><!-- /wp:heading -->
<!-- wp:paragraph --><p>Hơn 50 chậu cây nội thất tạo không gian trong lành, thoáng đãng, giúp bạn tập trung và thư giãn.</p><!-- /wp:paragraph -->
</div>
<!-- /wp:column -->
<!-- wp:column -->
<div class="wp-block-column">
<!-- wp:heading {"level":3} --><h3 class="wp-block-heading">📶 WiFi Siêu Tốc</h3><!-- /wp:heading -->
<!-- wp:paragraph --><p>Đường truyền 1Gbps, mỗi bàn có ổ cắm USB-C và 220V. Không gian lý tưởng để làm việc và học tập.</p><!-- /wp:paragraph -->
</div>
<!-- /wp:column -->
<!-- wp:column -->
<div class="wp-block-column">
<!-- wp:heading {"level":3} --><h3 class="wp-block-heading">🏆 Barista Chứng Nhận</h3><!-- /wp:heading -->
<!-- wp:paragraph --><p>Đội ngũ barista được chứng nhận SCA, đảm bảo mỗi tách cà phê đều hoàn hảo và nhất quán.</p><!-- /wp:paragraph -->
</div>
<!-- /wp:column -->
</div>
<!-- /wp:columns -->
CONTENT
)" \
    --porcelain)

$WP option update page_on_front "$HOME_ID"
$WP option update show_on_front "page"

# Menu page — static content (no WooCommerce dependency)
MENU_CONTENT='<!-- wp:heading {"textAlign":"center"} --><h2 class="wp-block-heading has-text-align-center">Thực Đơn IPMAC Café</h2><!-- /wp:heading --><!-- wp:paragraph {"align":"center"} --><p class="has-text-align-center">Tất cả nguyên liệu được tuyển chọn kỹ lưỡng từ các vùng sản xuất nổi tiếng</p><!-- /wp:paragraph --><!-- wp:separator --><hr class="wp-block-separator has-alpha-channel-opacity"/><!-- /wp:separator --><!-- wp:heading {"level":3} --><h3 class="wp-block-heading">Ca Phe Dac San</h3><!-- /wp:heading --><!-- wp:table {"className":"is-style-stripes"} --><figure class="wp-block-table is-style-stripes"><table><thead><tr><th>Mon</th><th>Mo ta</th><th>Gia</th></tr></thead><tbody><tr><td><strong>Espresso IPMAC</strong></td><td>Chiet xuat 25 giay, ap suat 9 bar, hau vi dai</td><td>45.000d</td></tr><tr><td><strong>Ca Phe Sua Da</strong></td><td>Ca phe Robusta pha phin truyen thong, sua dac</td><td>39.000d</td></tr><tr><td><strong>Cappuccino</strong></td><td>Espresso double shot, foam sua min kieu Y</td><td>59.000d</td></tr><tr><td><strong>Latte IPMAC</strong></td><td>Espresso + sua tuoi hap, ve latte art theo yeu cau</td><td>62.000d</td></tr><tr><td><strong>Cold Brew 12h</strong></td><td>U lanh 12 tieng, thanh mat, it chua</td><td>65.000d</td></tr><tr><td><strong>Brown Sugar Latte</strong></td><td>Espresso, sua tuoi, duong nau caramel</td><td>68.000d</td></tr></tbody></table></figure><!-- /wp:table --><!-- wp:heading {"level":3} --><h3 class="wp-block-heading">Tra va Thuc Uong Khac</h3><!-- /wp:heading --><!-- wp:table {"className":"is-style-stripes"} --><figure class="wp-block-table is-style-stripes"><table><thead><tr><th>Mon</th><th>Mo ta</th><th>Gia</th></tr></thead><tbody><tr><td><strong>Matcha Latte</strong></td><td>Matcha Nhat Ban grade A, sua tuoi hap</td><td>65.000d</td></tr><tr><td><strong>Hojicha Latte</strong></td><td>Tra rang Nhat Ban, huong thom dac trung</td><td>65.000d</td></tr><tr><td><strong>Tra Dao Cam Sa</strong></td><td>Tra xanh, dao tuoi, cam, sa tuoi</td><td>55.000d</td></tr><tr><td><strong>Bac Ha Chanh</strong></td><td>Chanh tuoi, bac ha, soda, duong thot not</td><td>45.000d</td></tr></tbody></table></figure><!-- /wp:table --><!-- wp:heading {"level":3} --><h3 class="wp-block-heading">Banh va Do An Nhe</h3><!-- /wp:heading --><!-- wp:table {"className":"is-style-stripes"} --><figure class="wp-block-table is-style-stripes"><table><thead><tr><th>Mon</th><th>Mo ta</th><th>Gia</th></tr></thead><tbody><tr><td><strong>Croissant Bo</strong></td><td>Croissant nhap tu lo banh Phap, bo Normandy</td><td>35.000d</td></tr><tr><td><strong>Tiramisu</strong></td><td>Ladyfinger tham espresso, mascarpone Y</td><td>55.000d</td></tr><tr><td><strong>Banh Mi Nuong Pho Mai</strong></td><td>Banh mi thu cong, pho mai Gouda tan chay</td><td>42.000d</td></tr><tr><td><strong>Granola Bowl</strong></td><td>Granola, sua chua Hy Lap, hoa qua tuoi theo mua</td><td>65.000d</td></tr></tbody></table></figure><!-- /wp:table --><!-- wp:paragraph {"align":"center"} --><p class="has-text-align-center"><em>Gia da bao gom VAT. Phuc vu tu 7:00 – 22:00 hang ngay.</em></p><!-- /wp:paragraph -->'

MENU_ID=$($WP post create \
    --post_title="Thực Đơn" \
    --post_status="publish" \
    --post_type="page" \
    --post_name="thuc-don" \
    --post_content="$MENU_CONTENT" \
    --porcelain)

# Create CF7 booking form first so we have its ID
CF7_ID=$($WP post create \
    --post_type="wpcf7_contact_form" \
    --post_status="publish" \
    --post_title="Dat Ban Form" \
    --porcelain 2>/dev/null || echo "")

# Insert CF7 form fields via meta
if [ -n "$CF7_ID" ]; then
    $WP post meta update "$CF7_ID" "_form" '<label>Họ và tên<br />[text* your-name placeholder "Nguyễn Văn A"]</label><label>Email<br />[email* your-email placeholder "email@example.com"]</label><label>Số điện thoại<br />[tel* phone placeholder "0912345678"]</label><label>Ngày đặt bàn<br />[date* booking-date]</label><label>Số người<br />[number* guests min:1 max:20 placeholder "2"]</label><label>Ghi chú<br />[textarea notes placeholder "Yêu cầu đặc biệt..."]</label>[submit "Đặt Bàn Ngay"]' 2>/dev/null || true
    $WP post meta update "$CF7_ID" "_mail" 'a:9:{s:2:"to";s:25:"admin@cafeipmac.local";s:4:"from";s:44:"IPMAC Café <wordpress@cafeipmac.local>";s:7:"subject";s:30:"[IPMAC Café] Đặt bàn mới";s:4:"body";s:100:"Họ tên: [your-name]\nEmail: [your-email]\nĐiện thoại: [phone]\nNgày: [booking-date]\nSố người: [guests]\nGhi chú: [notes]";s:18:"additional-headers";s:27:"Reply-To: [your-email]";s:11:"attachments";s:0:"";s:4:"use_html";s:0:"";s:13:"exclude_blank";s:0:"";s:16:"message-id-field";s:0:"";}' 2>/dev/null || true
    BOOKING_SHORTCODE="[contact-form-7 id=\"$CF7_ID\" title=\"Dat Ban Form\"]"
else
    BOOKING_SHORTCODE="[contact-form-7 title=\"Dat Ban Form\"]"
fi

# Booking page
BOOKING_ID=$($WP post create \
    --post_title="Đặt Bàn" \
    --post_status="publish" \
    --post_type="page" \
    --post_name="dat-ban" \
    --post_content="<!-- wp:heading {\"textAlign\":\"center\"} --><h2 class=\"wp-block-heading has-text-align-center\">📅 Đặt Bàn Trực Tuyến</h2><!-- /wp:heading --><!-- wp:paragraph --><p>Hãy điền thông tin để chúng tôi giữ bàn cho bạn. Xác nhận sẽ được gửi qua email trong vòng 30 phút.</p><!-- /wp:paragraph --><!-- wp:shortcode -->$BOOKING_SHORTCODE<!-- /wp:shortcode -->" \
    --porcelain)

# About page
$WP post create \
    --post_title="Về Chúng Tôi" \
    --post_status="publish" \
    --post_type="page" \
    --post_name="ve-chung-toi" \
    --post_content="<!-- wp:heading {\"textAlign\":\"center\"} --><h2 class=\"wp-block-heading has-text-align-center\">Câu Chuyện IPMAC Café</h2><!-- /wp:heading --><!-- wp:paragraph --><p>IPMAC Café được thành lập năm 2018 với sứ mệnh mang đến không gian cà phê kết hợp công nghệ. Chúng tôi tin rằng một tách cà phê ngon có thể trở thành người bạn đồng hành tuyệt vời trong hành trình học tập và làm việc của bạn.</p><!-- /wp:paragraph --><!-- wp:paragraph --><p>Với hơn 200 ghế ngồi, 50+ chậu cây xanh, âm nhạc lo-fi và WiFi tốc độ cao, IPMAC Café đã trở thành điểm đến yêu thích của hàng nghìn khách hàng tại TP.HCM.</p><!-- /wp:paragraph -->" \
    --porcelain 1>/dev/null

# Survey/Feedback page with Perfect Survey shortcode
$WP post create \
    --post_title="Khảo Sát & Phản Hồi" \
    --post_status="publish" \
    --post_type="page" \
    --post_name="khao-sat" \
    --post_content="<!-- wp:heading {\"textAlign\":\"center\"} --><h2 class=\"wp-block-heading has-text-align-center\">📝 Khảo Sát Trải Nghiệm</h2><!-- /wp:heading --><!-- wp:paragraph --><p>Ý kiến của bạn giúp chúng tôi không ngừng cải thiện dịch vụ. Hãy dành 2 phút để hoàn thành khảo sát!</p><!-- /wp:paragraph --><!-- wp:shortcode -->[ps-survey surveyId='1']<!-- /wp:shortcode -->" \
    --porcelain 1>/dev/null

echo "[IPMAC] Creating navigation menu..."
$WP menu create "Main Menu" || true
MENU_ID=$($WP menu list --fields=term_id --format=ids | head -1)
$WP menu item add-post "$MENU_ID" "$HOME_ID" --title="Trang Chủ" || true
$WP menu item add-post "$MENU_ID" "$BOOKING_ID" --title="Đặt Bàn" || true
$WP menu item add-custom "$MENU_ID" "Thực Đơn" "/thuc-don" || true
$WP menu item add-custom "$MENU_ID" "Về Chúng Tôi" "/ve-chung-toi" || true
$WP menu item add-custom "$MENU_ID" "Khảo Sát" "/khao-sat" || true
$WP menu location assign "$MENU_ID" primary || true

echo "[IPMAC] Creating WooCommerce products (cafe menu)..."
# Create product category
$WP term create product_cat "Cà Phê" --slug=ca-phe --description="Các loại cà phê đặc sản" || true
$WP term create product_cat "Trà & Khác" --slug=tra-khac --description="Trà và thức uống khác" || true

# Products
for i in 1 2 3; do
    $WP post create \
        --post_type=product \
        --post_status=publish \
        --post_title="Espresso IPMAC No.$i" \
        --post_content="Espresso đặc biệt với blend độc quyền. Chiết xuất 25 giây, áp suất 9 bar, nhiệt độ 93°C." \
        --porcelain > /dev/null 2>&1 || true
done

echo "[IPMAC] Creating Perfect Survey demo..."
# Use WP CLI to insert a survey via SQL
$WP db query "
INSERT IGNORE INTO wp_perfectsurvey_surveys (id, survey_name, survey_description, created_at, status)
VALUES
(1, 'Khảo sát trải nghiệm khách hàng', 'Giúp chúng tôi cải thiện dịch vụ tốt hơn', NOW(), 'active'),
(2, 'Đánh giá thực đơn mới', 'Bạn cảm thấy thế nào về thực đơn mới của chúng tôi?', NOW(), 'active')
ON DUPLICATE KEY UPDATE survey_name=survey_name;
" 2>/dev/null || true

$WP db query "
INSERT IGNORE INTO wp_perfectsurvey_questions (id, survey_id, question_text, question_type, options, sort_order)
VALUES
(1, 1, 'Bạn đánh giá chất lượng cà phê như thế nào?', 'radio', 'Xuất sắc,Tốt,Bình thường,Cần cải thiện', 1),
(2, 1, 'Không gian quán có thoải mái không?', 'radio', 'Rất thoải mái,Thoải mái,Chưa tốt', 2),
(3, 1, 'Bạn có muốn quay lại không?', 'radio', 'Chắc chắn,Có thể,Không', 3),
(4, 2, 'Bạn thích món nào nhất trong thực đơn mới?', 'checkbox', 'Espresso IPMAC,Café Sữa Đá,Matcha Latte,Brown Sugar Boba', 1),
(5, 2, 'Nhận xét thêm về thực đơn:', 'textarea', '', 2)
ON DUPLICATE KEY UPDATE question_text=question_text;
" 2>/dev/null || true

echo "[IPMAC] Configuring WordPress options for look and feel..."
$WP option update show_avatars 1
$WP option update uploads_use_yearmonth_folders 1
$WP option update blog_public 0

# Flush rewrite rules
$WP rewrite flush --hard

echo "[IPMAC] Flushing cache..."
$WP cache flush || true

touch "$SETUP_FLAG"
echo "[IPMAC] ✅ WordPress setup complete!"
echo "[IPMAC] URL: http://cafeipmac.local"
echo "[IPMAC] Admin: admin / hulabaloo"
