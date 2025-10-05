<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

/** Safe option getter with default */
function opt(string $key, $default = null) {
    $val = get_option($key, null);
    return (null === $val) ? $default : $val;
}

/** Currency formatting (MYR default) */
function money($amount): string {
    $cur = opt('krm_currency', 'MYR');
    return sprintf('%s %s', esc_html($cur), number_format((float)$amount, 2, '.', ','));
}

/** Current user can helper */
function can(string $cap): bool {
    return current_user_can($cap);
}

/** Sanitize decimal */
function dec($val, int $dp = 4) {
    return round((float) $val, $dp);
}
