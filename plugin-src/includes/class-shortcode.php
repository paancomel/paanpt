<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class Shortcode {
    public static function init() {
        add_shortcode('recipe_calculator', [__CLASS__, 'render']);
        add_action('wp_ajax_krm_save_menu', [__CLASS__, 'save_menu']);
        add_action('wp_ajax_nopriv_krm_save_menu', '__return_false');
    }

    public static function render($atts = array(), $content = '') {
        wp_enqueue_style('krm-frontend');
        wp_enqueue_style('krm-print');
        wp_enqueue_script('krm-frontend');
        $atts = shortcode_atts(array('id' => 0), $atts, 'recipe_calculator');
        $recipe_id = absint($atts['id']);
        ob_start();
        include KRM_PATH . 'templates/frontend-calculator.php';
        return ob_get_clean();
    }

    public static function save_menu() {
        check_ajax_referer('krm_nonce','nonce');
        if (!current_user_can('edit_recipes')) wp_send_json_error('no_permission', 403);

        $recipe_id = absint($_POST['recipe_id'] ?? 0);
        $rows = (array) ($_POST['rows'] ?? array());
        if (!$recipe_id || empty($rows)) wp_send_json_error('invalid', 400);

        global $wpdb;
        $table = DB::table_items();
        // wipe then insert (MVP)
        $wpdb->delete($table, array('recipe_post_id' => $recipe_id));
        foreach ($rows as $r) {
            $wpdb->insert($table, array(
                'recipe_post_id' => $recipe_id,
                'ingredient_post_id' => absint($r['ingredient_id'] ?? 0),
                'quantity' => (float) ($r['quantity'] ?? 0),
                'unit' => sanitize_text_field($r['unit'] ?? ''),
                'waste_pct' => (float) ($r['waste_pct'] ?? 0),
                'cost_snapshot' => (float) ($r['unit_cost'] ?? 0),
                'created_at' => current_time('mysql'),
                'updated_at' => current_time('mysql'),
            ));
        }
        wp_send_json_success(array('ok' => true));
    }
}
