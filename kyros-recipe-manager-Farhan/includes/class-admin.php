<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class Admin {
    public static function init() {
        add_action('admin_menu', [__CLASS__, 'menu']);
        add_action('admin_init', [__CLASS__, 'settings']);
    }

    public static function menu() {
        add_menu_page(__('Recipe Ops', KRM_TEXT_DOMAIN), __('Recipe Ops', KRM_TEXT_DOMAIN), 'read', 'krm_ops', [__CLASS__, 'dashboard'], 'dashicons-food', 25);
        add_submenu_page('krm_ops', __('Settings', KRM_TEXT_DOMAIN), __('Settings', KRM_TEXT_DOMAIN), 'krm_manage_settings', 'krm_settings', [__CLASS__, 'settings_page']);
    }

    public static function dashboard() {
        echo '<div class="wrap"><h1>Recipe Ops</h1><p>' . esc_html__('Use side menu to manage Ingredients and Recipes.', KRM_TEXT_DOMAIN) . '</p></div>';
    }

    public static function settings() {
        register_setting('krm_settings', 'krm_currency', ['sanitize_callback' => 'sanitize_text_field']);
        register_setting('krm_settings', 'krm_unit_system', ['sanitize_callback' => 'sanitize_text_field']);
        register_setting('krm_settings', 'krm_misc_pct', ['sanitize_callback' => 'absint']);
        register_setting('krm_settings', 'krm_cost_color_thresholds');
        register_setting('krm_settings', 'krm_allergens_master');

        add_settings_section('krm_main', __('General', KRM_TEXT_DOMAIN), '__return_false', 'krm_settings');

        add_settings_field('currency', __('Currency', KRM_TEXT_DOMAIN), function() {
            printf('<input type="text" name="krm_currency" value="%s" />', esc_attr(opt('krm_currency','MYR')));
        }, 'krm_settings', 'krm_main');

        add_settings_field('unit_system', __('Unit System', KRM_TEXT_DOMAIN), function() {
            $val = opt('krm_unit_system','metric');
            echo '<select name="krm_unit_system"><option value="metric" ' . selected($val,'metric',false) . '>metric</option><option value="imperial" ' . selected($val,'imperial',false) . '>imperial</option></select>';
        }, 'krm_settings', 'krm_main');

        add_settings_field('misc', __('Default Misc %', KRM_TEXT_DOMAIN), function() {
            printf('<input type="number" name="krm_misc_pct" value="%s" step="1" min="0" />', esc_attr(opt('krm_misc_pct',10)));
        }, 'krm_settings', 'krm_main');

        add_settings_field('allergens', __('Allergen Master List', KRM_TEXT_DOMAIN), function() {
            $vals = (array) opt('krm_allergens_master', array());
            printf('<textarea name="krm_allergens_master" rows="4" style="width:100%%">%s</textarea>', esc_textarea(implode(',', $vals)));
            echo '<p class="description">' . esc_html__('Comma-separated list. Examples: gluten, eggs, milk, peanuts…', KRM_TEXT_DOMAIN) . '</p>';
        }, 'krm_settings', 'krm_main');
    }

    public static function settings_page() {
        if (!current_user_can('krm_manage_settings')) { wp_die(__('You do not have permission.', KRM_TEXT_DOMAIN)); }
        echo '<div class="wrap"><h1>'. esc_html__('Kyros Recipe Manager Settings', KRM_TEXT_DOMAIN) .'</h1>';
        echo '<form method="post" action="options.php">';
        settings_fields('krm_settings');
        do_settings_sections('krm_settings');
        submit_button();
        echo '</form></div>';
    }
}
