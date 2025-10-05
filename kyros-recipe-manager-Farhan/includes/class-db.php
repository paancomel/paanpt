<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class DB {
    public static function table_items() {
        global $wpdb;
        return $wpdb->prefix . 'krm_recipe_items';
    }

    public static function maybe_install() {
        global $wpdb;
        $table = self::table_items();
        $charset_collate = $wpdb->get_charset_collate();
        $version = get_option('krm_db_version');

        $sql = "CREATE TABLE $table (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            recipe_post_id BIGINT UNSIGNED NOT NULL,
            ingredient_post_id BIGINT UNSIGNED NOT NULL,
            quantity DECIMAL(12,4) NOT NULL DEFAULT 0,
            unit VARCHAR(50) NOT NULL DEFAULT '',
            waste_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
            cost_snapshot DECIMAL(12,4) NOT NULL DEFAULT 0,
            created_at DATETIME NULL,
            updated_at DATETIME NULL,
            PRIMARY KEY  (id),
            KEY recipe_post_id (recipe_post_id),
            KEY ingredient_post_id (ingredient_post_id)
        ) $charset_collate;";

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';
        dbDelta($sql);
        if ($version !== '1') {
            update_option('krm_db_version','1');
        }
    }

    public static function items_for_recipe(int $recipe_id): array {
        global $wpdb;
        return $wpdb->get_results($wpdb->prepare("SELECT * FROM " . self::table_items() . " WHERE recipe_post_id=%d ORDER BY id ASC", $recipe_id), ARRAY_A) ?: array();
    }
}
