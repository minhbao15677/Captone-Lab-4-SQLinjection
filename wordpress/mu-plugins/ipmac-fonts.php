<?php
add_action('wp_head', function() {
    echo '<link rel="preconnect" href="https://fonts.googleapis.com">';
    echo '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>';
    echo '<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400&family=Playfair+Display:wght@700&display=swap" rel="stylesheet">';
    echo '<style>
body, button, input, select, textarea {
    font-family: "Be Vietnam Pro", -apple-system, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", Arial, sans-serif !important;
}
h1, h2, h3, h4, h5 {
    font-family: "Playfair Display", "Be Vietnam Pro", serif !important;
}
/* CF7 form styling */
.wpcf7 label {
    display: block;
    font-weight: 500;
    margin-top: 1.1rem;
    margin-bottom: 0.35rem;
    color: #333;
    font-size: 15px;
}
.wpcf7 input[type=text],
.wpcf7 input[type=email],
.wpcf7 input[type=tel],
.wpcf7 input[type=date],
.wpcf7 input[type=number],
.wpcf7 textarea {
    width: 100%;
    padding: 10px 14px;
    border: 1.5px solid #ddd;
    border-radius: 8px;
    font-size: 15px;
    font-family: "Be Vietnam Pro", sans-serif !important;
    background: #fafafa;
    transition: border-color .2s, box-shadow .2s;
    box-sizing: border-box;
}
.wpcf7 input[type=text]:focus,
.wpcf7 input[type=email]:focus,
.wpcf7 input[type=tel]:focus,
.wpcf7 input[type=date]:focus,
.wpcf7 input[type=number]:focus,
.wpcf7 textarea:focus {
    border-color: #C8860A;
    box-shadow: 0 0 0 3px rgba(200,134,10,0.12);
    outline: none;
    background: #fff;
}
.wpcf7 input[type=submit] {
    background: #C8860A;
    color: #fff;
    border: none;
    border-radius: 8px;
    padding: 12px 36px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    margin-top: 1.4rem;
    font-family: "Be Vietnam Pro", sans-serif !important;
    transition: background .2s, transform .1s;
}
.wpcf7 input[type=submit]:hover {
    background: #a36e08;
    transform: translateY(-1px);
}
.wpcf7 br { display: none; }
</style>';
}, 1);
