<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class Plugin {
    public static function init() {
        // CPTs
        CPT_Ingredient::init();
        CPT_Recipe::init();

        // Settings/Admin
        Admin::init();

        // Frontend + Shortcode + Block
        Shortcode::init();
        Block::init();

        // Assets
        add_action('wp_enqueue_scripts', [__CLASS__, 'frontend_assets']);
        add_action('admin_enqueue_scripts', [__CLASS__, 'admin_assets']);
    }

    public static function frontend_assets() {
        wp_register_style('krm-frontend', KRM_URL . 'assets/css/frontend.css', array(), KRM_VERSION);
        wp_register_style('krm-print', KRM_URL . 'assets/css/print.css', array(), KRM_VERSION, 'print');
        wp_register_script('krm-frontend', KRM_URL . 'assets/js/frontend-calculator.js', array('jquery'), KRM_VERSION, true);
        wp_localize_script('krm-frontend', 'KRM', array(
            'ajax' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('krm_nonce'),
            'currency' => opt('krm_currency', 'MYR'),
            'miscDefault' => (int) opt('krm_misc_pct', 10),
        ));
    }

    public static function admin_assets($hook) {
        wp_register_style('krm-admin', KRM_URL . 'assets/css/admin.css', array(), KRM_VERSION);
        wp_register_script('krm-admin-recipe', KRM_URL . 'assets/js/admin-recipe.js', array('jquery'), KRM_VERSION, true);
        wp_localize_script('krm-admin-recipe', 'KRMAdmin', array(
            'nonce' => wp_create_nonce('krm_nonce'),
            'allergens' => opt('krm_allergens_master', array()),
        ));
        wp_enqueue_style('krm-admin');

        if (function_exists('get_current_screen')) {
            $screen = get_current_screen();
            if ($screen && in_array($screen->post_type ?? '', array('recipe'), true)) {
                wp_enqueue_script('krm-admin-recipe');
            }
        }
    }
}
