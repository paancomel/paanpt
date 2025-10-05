<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class Admin {
    public static function init() {
        add_action('admin_menu', [__CLASS__, 'menu']);
        add_action('admin_init', [__CLASS__, 'settings']);
        add_filter('redirect_post_location', [__CLASS__, 'stay_on_edit'], 10, 2);
    }

    public static function menu() {
        add_menu_page(__('Recipe Ops', KRM_TEXT_DOMAIN), __('Recipe Ops', KRM_TEXT_DOMAIN), 'read', 'krm_ops', [__CLASS__, 'dashboard'], 'dashicons-food', 25);
        add_submenu_page('krm_ops', __('Dashboard', KRM_TEXT_DOMAIN), __('Dashboard', KRM_TEXT_DOMAIN), 'read', 'krm_ops', [__CLASS__, 'dashboard']);
        add_submenu_page('krm_ops', __('Settings', KRM_TEXT_DOMAIN), __('Settings', KRM_TEXT_DOMAIN), 'krm_manage_settings', 'krm_settings', [__CLASS__, 'settings_page']);
    }

    public static function dashboard() {
        $ingredient_counts = wp_count_posts('ingredient');
        $recipe_counts = wp_count_posts('recipe');
        $published_ingredients = (int) ($ingredient_counts->publish ?? 0);
        $draft_ingredients = (int) ($ingredient_counts->draft ?? 0);
        $published_recipes = (int) ($recipe_counts->publish ?? 0);
        $pending_recipes = (int) ($recipe_counts->pending ?? 0);

        echo '<div class="wrap krm-dashboard">';
        echo '<h1>' . esc_html__('Recipe Ops', KRM_TEXT_DOMAIN) . '</h1>';
        echo '<p class="krm-note">' . esc_html__('Quick overview of your ingredients and recipes. Use the shortcuts below to jump into action.', KRM_TEXT_DOMAIN) . '</p>';

        echo '<div class="krm-dashboard-grid">';
        self::dashboard_card(__('Ingredients', KRM_TEXT_DOMAIN), $published_ingredients, array(
            array('label' => __('Add Ingredient', KRM_TEXT_DOMAIN), 'link' => admin_url('post-new.php?post_type=ingredient')),
            array('label' => __('View All', KRM_TEXT_DOMAIN), 'link' => admin_url('edit.php?post_type=ingredient')),
        ), __('Drafts', KRM_TEXT_DOMAIN), $draft_ingredients);

        self::dashboard_card(__('Recipes', KRM_TEXT_DOMAIN), $published_recipes, array(
            array('label' => __('Add Recipe', KRM_TEXT_DOMAIN), 'link' => admin_url('post-new.php?post_type=recipe')),
            array('label' => __('View All', KRM_TEXT_DOMAIN), 'link' => admin_url('edit.php?post_type=recipe')),
        ), __('Pending Approval', KRM_TEXT_DOMAIN), $pending_recipes);

        echo '</div>';

        echo '<div class="krm-dashboard-actions">';
        echo '<h2>' . esc_html__('Need a hand?', KRM_TEXT_DOMAIN) . '</h2>';
        echo '<ul>';
        echo '<li><a class="button button-primary" href="' . esc_url(admin_url('post-new.php?post_type=recipe')) . '">' . esc_html__('Create New Recipe', KRM_TEXT_DOMAIN) . '</a></li>';
        echo '<li><a class="button" href="' . esc_url(admin_url('admin.php?page=krm_settings')) . '">' . esc_html__('Review Settings', KRM_TEXT_DOMAIN) . '</a></li>';
        echo '</ul>';
        echo '</div>';
        echo '</div>';
    }

    private static function dashboard_card($title, $primary_count, $links, $secondary_label, $secondary_count) {
        echo '<div class="krm-dashboard-card">';
        echo '<h3>' . esc_html($title) . '</h3>';
        echo '<div class="krm-dashboard-total">' . intval($primary_count) . '</div>';
        echo '<p class="krm-dashboard-sub">' . esc_html($secondary_label) . ': ' . intval($secondary_count) . '</p>';
        if (!empty($links)) {
            echo '<ul class="krm-dashboard-links">';
            foreach ($links as $link) {
                echo '<li><a href="' . esc_url($link['link']) . '">' . esc_html($link['label']) . '</a></li>';
            }
            echo '</ul>';
        }
        echo '</div>';
    }

    public static function settings() {
        register_setting('krm_settings', 'krm_currency', ['sanitize_callback' => 'sanitize_text_field']);
        register_setting('krm_settings', 'krm_unit_system', ['sanitize_callback' => 'sanitize_text_field']);
        register_setting('krm_settings', 'krm_misc_pct', ['sanitize_callback' => 'absint']);
        register_setting('krm_settings', 'krm_cost_color_thresholds');
        register_setting('krm_settings', 'krm_allergens_master');

        add_settings_section('krm_main', __('General', KRM_TEXT_DOMAIN), '__return_false', 'krm_settings');

        add_settings_field('currency', __('Currency', KRM_TEXT_DOMAIN), function() {
            printf('<input type="text" name="krm_currency" value="%s" />', esc_attr(opt('krm_currency', 'MYR')));
        }, 'krm_settings', 'krm_main');

        add_settings_field('unit_system', __('Unit System', KRM_TEXT_DOMAIN), function() {
            $val = opt('krm_unit_system', 'metric');
            echo '<select name="krm_unit_system"><option value="metric" ' . selected($val, 'metric', false) . '>metric</option><option value="imperial" ' . selected($val, 'imperial', false) . '>imperial</option></select>';
        }, 'krm_settings', 'krm_main');

        add_settings_field('misc', __('Default Misc %', KRM_TEXT_DOMAIN), function() {
            printf('<input type="number" name="krm_misc_pct" value="%s" step="1" min="0" />', esc_attr(opt('krm_misc_pct', 10)));
        }, 'krm_settings', 'krm_main');

        add_settings_field('allergens', __('Allergen Master List', KRM_TEXT_DOMAIN), function() {
            $vals = (array) opt('krm_allergens_master', array());
            echo '<textarea name="krm_allergens_master" rows="4" style="width:100%">' . esc_textarea(implode(",", $vals)) . '</textarea>';
            echo '<p class="description">' . esc_html__('Comma-separated list. Examples: gluten, eggs, milk, peanuts…', KRM_TEXT_DOMAIN) . '</p>';
        }, 'krm_settings', 'krm_main');
    }

    public static function settings_page() {
        if (!current_user_can('krm_manage_settings')) {
            wp_die(__('You do not have permission.', KRM_TEXT_DOMAIN));
        }
        echo '<div class="wrap"><h1>' . esc_html__('Kyros Recipe Manager Settings', KRM_TEXT_DOMAIN) . '</h1>';
        echo '<form method="post" action="options.php">';
        settings_fields('krm_settings');
        do_settings_sections('krm_settings');
        submit_button();
        echo '</form></div>';
    }

    public static function stay_on_edit($location, $post_id) {
        if (!$post_id) {
            return $location;
        }

        $post_type = get_post_type($post_id);
        if (!in_array($post_type, array('ingredient', 'recipe'), true)) {
            return $location;
        }

        $query = array();
        $parsed = wp_parse_url($location);
        if (!empty($parsed['query'])) {
            parse_str($parsed['query'], $query);
        }

        $query['post'] = $post_id;
        $query['action'] = 'edit';

        return add_query_arg($query, admin_url('post.php'));
    }
}
