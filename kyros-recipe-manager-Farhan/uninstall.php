<?php
defined('WP_UNINSTALL_PLUGIN') || exit;

global $wpdb;
$prefix = $wpdb->prefix;
$table  = $prefix . 'krm_recipe_items';
$wpdb->query("DROP TABLE IF EXISTS $table");

// Delete options
$opts = array(
  'krm_currency',
  'krm_unit_system',
  'krm_misc_pct',
  'krm_cost_color_thresholds',
  'krm_allergens_master',
  'krm_db_version'
);
foreach ($opts as $o) { delete_option($o); }

// Remove roles/caps
require_once __DIR__ . '/includes/class-roles.php';
\Kyros\RecipeManager\Roles::remove_caps();
\Kyros\RecipeManager\Roles::remove_roles();
