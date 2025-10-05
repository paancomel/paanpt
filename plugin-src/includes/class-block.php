<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class Block {
    public static function init() {
        add_action('init', [__CLASS__, 'register_block']);
    }

    public static function register_block() {
        // Minimal dynamic block that reuses shortcode render
        register_block_type_from_metadata(KRM_PATH . 'includes', array(
            'render_callback' => function($atts) {
                $id = isset($atts['recipeId']) ? intval($atts['recipeId']) : 0;
                return do_shortcode('[recipe_calculator id="' . $id . '"]');
            }
        ));
        wp_register_script('krm-block', KRM_URL . 'assets/js/block.js', array('wp-blocks','wp-element','wp-editor'), KRM_VERSION, true);
        wp_set_script_translations('krm-block', KRM_TEXT_DOMAIN, KRM_PATH . 'languages');
    }
}
