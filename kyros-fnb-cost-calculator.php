<?php
/**
 * Plugin Name: Kyros F&B Cost Calculator
 * Plugin URI: https://kyros.com
 * Description: WordPress admin experience for the Kyros F&B cost calculator backed by GitHub content and featuring PDF/Excel exports.
 * Version: 1.0.0
 * Author: Kyros Digital
 * License: MIT
 * License URI: https://opensource.org/licenses/MIT
 * Text Domain: kyros-fnb
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

define( 'KYROS_FNB_PLUGIN_FILE', __FILE__ );
define( 'KYROS_FNB_PLUGIN_PATH', plugin_dir_path( __FILE__ ) );
define( 'KYROS_FNB_PLUGIN_URL', plugin_dir_url( __FILE__ ) );

require_once KYROS_FNB_PLUGIN_PATH . 'includes/class-kyros-fnb-github-client.php';
require_once KYROS_FNB_PLUGIN_PATH . 'includes/class-kyros-fnb-plugin.php';

Kyros_FnB_Cost_Calculator::instance();
