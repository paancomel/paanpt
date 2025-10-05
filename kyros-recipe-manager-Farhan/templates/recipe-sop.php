<?php
defined('ABSPATH') || exit;
/* Placeholder SOP template; enhance as needed. */
the_post();
echo '<h1>' . esc_html(get_the_title()) . '</h1>';
echo '<div>' . wp_kses_post(get_the_excerpt()) . '</div>';
