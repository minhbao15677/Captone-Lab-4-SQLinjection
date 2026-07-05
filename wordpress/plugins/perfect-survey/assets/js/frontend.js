jQuery(document).ready(function($) {
    var surveyId = PS_AJAX.survey_id;
    var wrap = $('#ps-survey-wrap');

    // Load survey via AJAX (vulnerable endpoint)
    $.ajax({
        url: PS_AJAX.ajax_url,
        type: 'GET',
        data: {
            action: 'ps_load_survey',
            survey_id: surveyId
        },
        success: function(response) {
            if (!response.success || !response.data || !response.data.length) {
                $('#ps-loading').html('<p>Không tìm thấy khảo sát.</p>');
                return;
            }

            var rows = response.data;
            var surveyName = rows[0].survey_name || 'Khảo sát';
            var html = '<h3 class="ps-title">' + surveyName + '</h3>';
            html += '<form id="ps-form">';

            var seen = {};
            rows.forEach(function(row) {
                if (!row.qid || seen[row.qid]) return;
                seen[row.qid] = true;

                html += '<div class="ps-question" data-qid="' + row.qid + '">';
                html += '<p class="ps-q-text">' + row.question_text + '</p>';

                if (row.question_type === 'radio' || row.question_type === 'checkbox') {
                    var opts = (row.options || '').split(',');
                    opts.forEach(function(opt, i) {
                        opt = opt.trim();
                        var inputType = row.question_type;
                        var name = inputType === 'radio' ? 'q_' + row.qid : 'q_' + row.qid + '[]';
                        html += '<label class="ps-option">';
                        html += '<input type="' + inputType + '" name="' + name + '" value="' + opt + '"> ';
                        html += opt;
                        html += '</label>';
                    });
                } else if (row.question_type === 'textarea') {
                    html += '<textarea name="q_' + row.qid + '" class="ps-textarea" rows="4" placeholder="Nhập câu trả lời..."></textarea>';
                }

                html += '</div>';
            });

            html += '<button type="submit" class="ps-submit-btn">Gửi Khảo Sát ✓</button>';
            html += '</form>';

            $('#ps-content').html(html).show();
            $('#ps-loading').hide();
        },
        error: function() {
            $('#ps-loading').html('<p>Lỗi tải khảo sát. Vui lòng thử lại.</p>');
        }
    });

    // Submit handler
    $(document).on('submit', '#ps-form', function(e) {
        e.preventDefault();
        var $form = $(this);
        var $btn = $form.find('.ps-submit-btn');
        $btn.prop('disabled', true).text('Đang gửi...');

        var questions = wrap.find('.ps-question');
        var requests = [];

        questions.each(function() {
            var qid = $(this).data('qid');
            var answer = '';
            var inputs = $(this).find('input[type=radio]:checked, input[type=checkbox]:checked');
            if (inputs.length) {
                answer = inputs.map(function() { return $(this).val(); }).get().join(', ');
            } else {
                answer = $(this).find('textarea').val() || '';
            }

            if (answer) {
                requests.push($.ajax({
                    url: PS_AJAX.ajax_url,
                    type: 'POST',
                    data: {
                        action: 'ps_submit_answer',
                        survey_id: surveyId,
                        question_id: qid,
                        answer: answer,
                        _wpnonce: PS_AJAX.nonce
                    }
                }));
            }
        });

        $.when.apply($, requests).then(function() {
            $('#ps-content').hide();
            $('#ps-success').fadeIn();
        });
    });
});
