<?php
/**
 * Plugin Name:  Kyros Recipe Manager By Farhan
 * Plugin URI:   https://example.com
 * Description:  Internal recipe & ingredient management with live cost calculator, roles, approvals, PDF export, shortcode & block.
 * Version:      1.3.0
 * Author:       Farhan
 * Author URI:   https://example.com
 * Text Domain:  kyros-recipe-manager
 * Requires PHP: 7.4
 * Requires at least: 6.0
 * License: GPLv2 or later
 */

defined('ABSPATH') || exit;

define('KRM_VERSION', '1.3.0');
define('KRM_FILE', __FILE__);
define('KRM_PATH', plugin_dir_path(__FILE__));
define('KRM_URL',  plugin_dir_url(__FILE__));
define('KRM_TEXT_DOMAIN', 'kyros-recipe-manager');

require_once KRM_PATH . 'includes/helpers.php';
require_once KRM_PATH . 'includes/class-roles.php';
require_once KRM_PATH . 'includes/class-db.php';
require_once KRM_PATH . 'includes/class-plugin.php';
require_once KRM_PATH . 'includes/class-cpt-ingredient.php';
require_once KRM_PATH . 'includes/class-cpt-recipe.php';
require_once KRM_PATH . 'includes/class-admin.php';
require_once KRM_PATH . 'includes/class-calculator.php';
require_once KRM_PATH . 'includes/class-shortcode.php';
require_once KRM_PATH . 'includes/class-export.php';
require_once KRM_PATH . 'includes/class-notify.php';
require_once KRM_PATH . 'includes/class-block.php';

register_activation_hook(__FILE__, function() {
    \Kyros\RecipeManager\Roles::add_roles();
    \Kyros\RecipeManager\Roles::add_caps();
    \Kyros\RecipeManager\DB::maybe_install();
    // defaults
    add_option('krm_currency', 'MYR');
    add_option('krm_unit_system', 'metric');
    add_option('krm_misc_pct', (int) 10);
    add_option('krm_cost_color_thresholds', array('good' => 30, 'warn' => 40));
    // Allergen master list
    add_option('krm_allergens_master', array(
        'gluten','crustaceans','eggs','fish','peanuts','soybeans','milk','tree_nuts',
        'celery','mustard','sesame','sulphites','lupin','molluscs'
    ));
    flush_rewrite_rules();
});

register_deactivation_hook(__FILE__, function() {
    flush_rewrite_rules();
});

add_action('plugins_loaded', function() {
    load_plugin_textdomain('kyros-recipe-manager', false, dirname(plugin_basename(__FILE__)) . '/languages');
    \Kyros\RecipeManager\Plugin::init();
});
