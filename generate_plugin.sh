#!/usr/bin/env bash
set -e

PLUGIN_SLUG="kyros-recipe-manager-Farhan"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"
ZIP_PATH="$SCRIPT_DIR/${PLUGIN_SLUG}.zip"

cd "$SCRIPT_DIR"

python3 - <<'PY'
from pathlib import Path
ROOT = Path('kyros-recipe-manager-Farhan')
FILES = {}
FILES['README_RUN.txt'] = '# How to run\n\n1) Save this script as generate_plugin.sh\n2) Run: bash generate_plugin.sh\n3) Copy the generated folder "kyros-recipe-manager-Farhan/" into your WordPress "wp-content/plugins/" directory.\n4) In WP Admin → Plugins, activate **Kyros Recipe Manager By Farhan**.\n5) Go to **Recipe Ops → Settings** to set currency (MYR), unit system, misc %, allergens.\n6) Create **Ingredients** with base unit, price per base, supplier & allergens.\n7) Create a **Recipe**, then view the front-end with shortcode:\n   [recipe_calculator id="RECIPE_ID"]\n   or add the **Recipe Calculator** block.\n8) Use **Save Menu** to persist line items; print the SOP using the browser print dialog.\n\nNotes:\n- This is an MVP scaffold with secure defaults. Improve UI/UX and add PDF engine later if needed.\n'
FILES['assets/css/admin.css'] = ".krm-note{color:#666;margin-bottom:1rem}
.krm-dashboard-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;margin:20px 0}
.krm-dashboard-card{background:#fff;border:1px solid #eaeaea;border-radius:10px;padding:16px;box-shadow:0 1px 3px rgba(0,0,0,.05)}
.krm-dashboard-total{font-size:32px;font-weight:700;color:#d32f2f;margin:0}
.krm-dashboard-sub{margin:8px 0 12px;font-size:14px;color:#555}
.krm-dashboard-links{margin:0;padding:0;list-style:none}
.krm-dashboard-links li{margin-bottom:6px}
.krm-dashboard-links a{text-decoration:none}
.krm-dashboard-actions ul{margin:0;padding:0;list-style:none;display:flex;gap:12px;flex-wrap:wrap}
.krm-dashboard-actions .button-primary{background:#d32f2f;border-color:#d32f2f}
"
FILES['assets/css/frontend.css'] = '/* Minimal clean UI; improve freely */\n.krm-card{background:#fff;border:1px solid #eee;border-radius:14px;padding:18px;box-shadow:0 1px 3px rgba(0,0,0,.05);max-width:980px;margin:20px auto}\n.krm-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px}\n.krm-table{width:100%;border-collapse:separate;border-spacing:0 8px}\n.krm-table th,.krm-table td{padding:10px;border-bottom:1px solid #f1f1f1}\n.krm-table .krm-right{text-align:right}\n.krm-add{background:#d32f2f;border-color:#d32f2f}\n.krm-summary{display:flex;gap:20px;flex-wrap:wrap;margin-top:10px}\n.krm-box{background:#fafafa;border:1px solid #eee;padding:12px;border-radius:10px;min-width:220px}\n.krm-badge{font-weight:700}\n.krm-total-final{font-size:20px;text-align:right;margin-top:10px;color:#c62828}\n@media(max-width:640px){\n  .krm-table thead{display:none}\n  .krm-table tr{display:block}\n  .krm-table td{display:flex;justify-content:space-between}\n}\n'
FILES['assets/css/print.css'] = '@media print {\n  .site-header,.site-footer,.widget-area,.krm-add,.krm-del,#wpadminbar{display:none!important}\n  .krm-card{box-shadow:none;border:none}\n}\n'
FILES['assets/js/admin-recipe.js'] = '(function($){\n  $(\'#krm-add-dir\').on(\'click\', function(){\n    var i = $(\'#krm-dirs-body tr\').length;\n    var row = $(\'<tr>\\\n      <td><input type="number" name="krm_dirs[\'+i+\'][step_no]" value="\'+(i+1)+\'" /></td>\\\n      <td><textarea name="krm_dirs[\'+i+\'][instruction]" rows="2" style="width:100%"></textarea></td>\\\n    </tr>\');\n    $(\'#krm-dirs-body\').append(row);\n  });\n})(jQuery);\n'
FILES['assets/js/block.js'] = "(function(wp){\n  const el = wp.element.createElement;\n  const registerBlockType = wp.blocks.registerBlockType;\n\n  registerBlockType('krm/recipe-calculator', {\n    title: 'Recipe Calculator',\n    icon: 'clipboard',\n    category: 'widgets',\n    attributes: { recipeId: { type: 'number', default: 0 } },\n    edit: function(props){\n      return el('div', {className:'krm-block'},\n        el('label', null, 'Recipe ID: ',\n          el('input', {type:'number', value: props.attributes.recipeId,\n            onChange: (e)=>props.setAttributes({recipeId: parseInt(e.target.value||0,10)})})\n        ),\n        el('p', null, 'This block renders the front-end calculator for the selected recipe.')\n      );\n    },\n    save: function(){ return null; } // dynamic\n  });\n})(window.wp);\n"
FILES['assets/js/frontend-calculator.js'] = '(function($){\n  function fmt(n){ return \'RM \' + Number(n||0).toFixed(2); }\n  function recalc(){\n    var total = 0;\n    $(\'#krm-rows tr.krm-row\').each(function(){\n      var qty = parseFloat($(\'.krm-qty\', this).val())||0;\n      var cost = parseFloat($(\'.krm-cost\', this).val())||0;\n      var sub = qty * cost; // waste handled in future per-row\n      total += sub;\n      $(\'.krm-subtotal\', this).text(fmt(sub));\n    });\n    $(\'.krm-total\').text(fmt(total));\n    var miscPct = parseFloat($(\'#krm-misc\').val())||0;\n    var miscRM = total * (miscPct/100);\n    $(\'.krm-misc-rm\').text(fmt(miscRM));\n    var grand = total + miscRM;\n    $(\'#krm-grand\').text(fmt(grand));\n    var sell = parseFloat($(\'#krm-sell\').val())||0;\n    var pct = sell>0 ? ((total/sell)*100) : 0;\n    var badge = $(\'#krm-costpct\').text(pct.toFixed(1)+\'%\');\n    badge.removeClass(\'good warn bad\');\n    if (pct<=30) badge.addClass(\'good\'); else if (pct<=40) badge.addClass(\'warn\'); else badge.addClass(\'bad\');\n  }\n  $(document).on(\'input change\',\'#krm-rows input, #krm-misc, #krm-sell\', recalc);\n  $(document).on(\'click\',\'.krm-add\', function(){\n    var row = $(\'<tr class="krm-row">\\\n      <td><input type="text" class="krm-ingredient" placeholder="Select…" /></td>\\\n      <td><select class="krm-unit"><option>g</option><option>kg</option><option>ml</option><option>L</option><option>piece</option></select></td>\\\n      <td><input type="number" step="0.0001" class="krm-cost" value="0" /></td>\\\n      <td><input type="number" step="0.0001" class="krm-qty" value="0" /></td>\\\n      <td class="krm-right krm-subtotal">RM 0.00</td>\\\n      <td><button class="krm-del">🗑</button></td>\\\n    </tr>\');\n    $(\'#krm-rows\').append(row);\n    recalc();\n  });\n  $(document).on(\'click\',\'.krm-del\', function(e){ e.preventDefault(); $(this).closest(\'tr\').remove(); recalc(); });\n\n  $(\'#krm-save-menu\').on(\'click\', function(e){\n    e.preventDefault();\n    var recipeId = parseInt($(\'#krm-recipe-id\').val()||0,10);\n    if (!recipeId){ alert(\'No recipe ID.\'); return; }\n    var rows = [];\n    $(\'#krm-rows tr.krm-row\').each(function(){\n      rows.push({\n        ingredient_id: 0, // MVP, manual typed name\n        unit: $(\'.krm-unit\', this).val(),\n        unit_cost: parseFloat($(\'.krm-cost\', this).val())||0,\n        quantity: parseFloat($(\'.krm-qty\', this).val())||0,\n        waste_pct: 0\n      });\n    });\n    $.post(KRM.ajax, {action:\'krm_save_menu\', nonce:KRM.nonce, recipe_id:recipeId, rows:rows}, function(resp){\n      if (resp && resp.success){ alert(\'Saved\'); } else { alert(\'Save failed\'); }\n    });\n  });\n\n  $(function(){ recalc(); });\n})(jQuery);\n'
FILES['includes/block.json'] = '{\n  "apiVersion": 3,\n  "name": "krm/recipe-calculator",\n  "title": "Recipe Calculator",\n  "category": "widgets",\n  "icon": "clipboard",\n  "attributes": { "recipeId": { "type": "number", "default": 0 } },\n  "editorScript": "krm-block"\n}\n'
FILES['includes/class-admin.php'] = "<?php
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

        echo '<div class=\"wrap krm-dashboard\">';
        echo '<h1>' . esc_html__('Recipe Ops', KRM_TEXT_DOMAIN) . '</h1>';
        echo '<p class=\"krm-note\">' . esc_html__('Quick overview of your ingredients and recipes. Use the shortcuts below to jump into action.', KRM_TEXT_DOMAIN) . '</p>';

        echo '<div class=\"krm-dashboard-grid\">';
        self::dashboard_card(__('Ingredients', KRM_TEXT_DOMAIN), $published_ingredients, array(
            array('label' => __('Add Ingredient', KRM_TEXT_DOMAIN), 'link' => admin_url('post-new.php?post_type=ingredient')),
            array('label' => __('View All', KRM_TEXT_DOMAIN), 'link' => admin_url('edit.php?post_type=ingredient')),
        ), __('Drafts', KRM_TEXT_DOMAIN), $draft_ingredients);

        self::dashboard_card(__('Recipes', KRM_TEXT_DOMAIN), $published_recipes, array(
            array('label' => __('Add Recipe', KRM_TEXT_DOMAIN), 'link' => admin_url('post-new.php?post_type=recipe')),
            array('label' => __('View All', KRM_TEXT_DOMAIN), 'link' => admin_url('edit.php?post_type=recipe')),
        ), __('Pending Approval', KRM_TEXT_DOMAIN), $pending_recipes);

        echo '</div>';

        echo '<div class=\"krm-dashboard-actions\">';
        echo '<h2>' . esc_html__('Need a hand?', KRM_TEXT_DOMAIN) . '</h2>';
        echo '<ul>';
        echo '<li><a class=\"button button-primary\" href=\"' . esc_url(admin_url('post-new.php?post_type=recipe')) . '\">' . esc_html__('Create New Recipe', KRM_TEXT_DOMAIN) . '</a></li>';
        echo '<li><a class=\"button\" href=\"' . esc_url(admin_url('admin.php?page=krm_settings')) . '\">' . esc_html__('Review Settings', KRM_TEXT_DOMAIN) . '</a></li>';
        echo '</ul>';
        echo '</div>';
        echo '</div>';
    }

    private static function dashboard_card($title, $primary_count, $links, $secondary_label, $secondary_count) {
        echo '<div class=\"krm-dashboard-card\">';
        echo '<h3>' . esc_html($title) . '</h3>';
        echo '<div class=\"krm-dashboard-total\">' . intval($primary_count) . '</div>';
        echo '<p class=\"krm-dashboard-sub\">' . esc_html($secondary_label) . ': ' . intval($secondary_count) . '</p>';
        if (!empty($links)) {
            echo '<ul class=\"krm-dashboard-links\">';
            foreach ($links as $link) {
                echo '<li><a href=\"' . esc_url($link['link']) . '\">' . esc_html($link['label']) . '</a></li>';
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
            printf('<input type=\"text\" name=\"krm_currency\" value=\"%s\" />', esc_attr(opt('krm_currency', 'MYR')));
        }, 'krm_settings', 'krm_main');

        add_settings_field('unit_system', __('Unit System', KRM_TEXT_DOMAIN), function() {
            $val = opt('krm_unit_system', 'metric');
            echo '<select name=\"krm_unit_system\"><option value=\"metric\" ' . selected($val, 'metric', false) . '>metric</option><option value=\"imperial\" ' . selected($val, 'imperial', false) . '>imperial</option></select>';
        }, 'krm_settings', 'krm_main');

        add_settings_field('misc', __('Default Misc %', KRM_TEXT_DOMAIN), function() {
            printf('<input type=\"number\" name=\"krm_misc_pct\" value=\"%s\" step=\"1\" min=\"0\" />', esc_attr(opt('krm_misc_pct', 10)));
        }, 'krm_settings', 'krm_main');

        add_settings_field('allergens', __('Allergen Master List', KRM_TEXT_DOMAIN), function() {
            $vals = (array) opt('krm_allergens_master', array());
            echo '<textarea name=\"krm_allergens_master\" rows=\"4\" style=\"width:100%\">' . esc_textarea(implode(\",\", $vals)) . '</textarea>';
            echo '<p class=\"description\">' . esc_html__('Comma-separated list. Examples: gluten, eggs, milk, peanuts…', KRM_TEXT_DOMAIN) . '</p>';
        }, 'krm_settings', 'krm_main');
    }

    public static function settings_page() {
        if (!current_user_can('krm_manage_settings')) {
            wp_die(__('You do not have permission.', KRM_TEXT_DOMAIN));
        }
        echo '<div class=\"wrap\"><h1>' . esc_html__('Kyros Recipe Manager Settings', KRM_TEXT_DOMAIN) . '</h1>';
        echo '<form method=\"post\" action=\"options.php\">';
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
"wrap krm-dashboard\">';
        echo '<h1>' . esc_html__('Recipe Ops', KRM_TEXT_DOMAIN) . '</h1>';
        echo '<p class=\"krm-note\">' . esc_html__('Quick overview of your ingredients and recipes. Use the shortcuts below to jump into action.', KRM_TEXT_DOMAIN) . '</p>';

        echo '<div class=\"krm-dashboard-grid\">';
        self::dashboard_card(__('Ingredients', KRM_TEXT_DOMAIN), $published_ingredients, array(
            array('label' => __('Add Ingredient', KRM_TEXT_DOMAIN), 'link' => admin_url('post-new.php?post_type=ingredient')),
            array('label' => __('View All', KRM_TEXT_DOMAIN), 'link' => admin_url('edit.php?post_type=ingredient')),
        ), __('Drafts', KRM_TEXT_DOMAIN), $draft_ingredients);

        self::dashboard_card(__('Recipes', KRM_TEXT_DOMAIN), $published_recipes, array(
            array('label' => __('Add Recipe', KRM_TEXT_DOMAIN), 'link' => admin_url('post-new.php?post_type=recipe')),
            array('label' => __('View All', KRM_TEXT_DOMAIN), 'link' => admin_url('edit.php?post_type=recipe')),
        ), __('Pending Approval', KRM_TEXT_DOMAIN), $pending_recipes);

        echo '</div>';

        echo '<div class=\"krm-dashboard-actions\">';
        echo '<h2>' . esc_html__('Need a hand?', KRM_TEXT_DOMAIN) . '</h2>';
        echo '<ul>';
        echo '<li><a class=\"button button-primary\" href=\"' . esc_url(admin_url('post-new.php?post_type=recipe')) . '\">' . esc_html__('Create New Recipe', KRM_TEXT_DOMAIN) . '</a></li>';
        echo '<li><a class=\"button\" href=\"' . esc_url(admin_url('admin.php?page=krm_settings')) . '\">' . esc_html__('Review Settings', KRM_TEXT_DOMAIN) . '</a></li>';
        echo '</ul>';
        echo '</div>';
        echo '</div>';
    }

    private static function dashboard_card($title, $primary_count, $links, $secondary_label, $secondary_count) {
        echo '<div class=\"krm-dashboard-card\">';
        echo '<h3>' . esc_html($title) . '</h3>';
        echo '<div class=\"krm-dashboard-total\">' . intval($primary_count) . '</div>';
        echo '<p class=\"krm-dashboard-sub\">' . esc_html($secondary_label) . ': ' . intval($secondary_count) . '</p>';
        if (!empty($links)) {
            echo '<ul class=\"krm-dashboard-links\">';
            foreach ($links as $link) {
                echo '<li><a href=\"' . esc_url($link['link']) . '\">' . esc_html($link['label']) . '</a></li>';
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
            printf('<input type=\"text\" name=\"krm_currency\" value=\"%s\" />', esc_attr(opt('krm_currency', 'MYR')));
        }, 'krm_settings', 'krm_main');

        add_settings_field('unit_system', __('Unit System', KRM_TEXT_DOMAIN), function() {
            $val = opt('krm_unit_system', 'metric');
            echo '<select name=\"krm_unit_system\"><option value=\"metric\" ' . selected($val, 'metric', false) . '>metric</option><option value=\"imperial\" ' . selected($val, 'imperial', false) . '>imperial</option></select>';
        }, 'krm_settings', 'krm_main');

        add_settings_field('misc', __('Default Misc %', KRM_TEXT_DOMAIN), function() {
            printf('<input type=\"number\" name=\"krm_misc_pct\" value=\"%s\" step=\"1\" min=\"0\" />', esc_attr(opt('krm_misc_pct', 10)));
        }, 'krm_settings', 'krm_main');

        add_settings_field('allergens', __('Allergen Master List', KRM_TEXT_DOMAIN), function() {
            $vals = (array) opt('krm_allergens_master', array());
            echo '<textarea name=\"krm_allergens_master\" rows=\"4\" style=\"width:100%\">' . esc_textarea(implode(\",\", $vals)) . '</textarea>';
            echo '<p class=\"description\">' . esc_html__('Comma-separated list. Examples: gluten, eggs, milk, peanuts…', KRM_TEXT_DOMAIN) . '</p>';
        }, 'krm_settings', 'krm_main');
    }

    public static function settings_page() {
        if (!current_user_can('krm_manage_settings')) {
            wp_die(__('You do not have permission.', KRM_TEXT_DOMAIN));
        }
        echo '<div class=\"wrap\"><h1>' . esc_html__('Kyros Recipe Manager Settings', KRM_TEXT_DOMAIN) . '</h1>';
        echo '<form method=\"post\" action=\"options.php\">';
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
"ABSPATH\') || exit;\n\nclass Admin {\n    public static function init() {\n        add_action(\'admin_menu\', [__CLASS__, \'menu\']);\n        add_action(\'admin_init\', [__CLASS__, \'settings\']);\n    }\n\n    public static function menu() {\n        add_menu_page(__(\'Recipe Ops\', KRM_TEXT_DOMAIN), __(\'Recipe Ops\', KRM_TEXT_DOMAIN), \'read\', \'krm_ops\', [__CLASS__, \'dashboard\'], \'dashicons-food\', 25);\n        remove_submenu_page(\'krm_ops\', \'krm_ops\');\n        add_submenu_page(\'krm_ops\', __(\'Dashboard\', KRM_TEXT_DOMAIN), __(\'Dashboard\', KRM_TEXT_DOMAIN), \'read\', \'krm_ops\', [__CLASS__, \'dashboard\']);\n        add_submenu_page(\'krm_ops\', __(\'Ingredients\', KRM_TEXT_DOMAIN), __(\'Ingredients\', KRM_TEXT_DOMAIN), \'read_ingredient\', \'edit.php?post_type=ingredient\');\n        add_submenu_page(\'krm_ops\', __(\'Add Ingredient\', KRM_TEXT_DOMAIN), __(\'Add Ingredient\', KRM_TEXT_DOMAIN), \'edit_ingredient\', \'post-new.php?post_type=ingredient\');\n        add_submenu_page(\'krm_ops\', __(\'Recipes\', KRM_TEXT_DOMAIN), __(\'Recipes\', KRM_TEXT_DOMAIN), \'read_recipe\', \'edit.php?post_type=recipe\');\n        add_submenu_page(\'krm_ops\', __(\'Add Recipe\', KRM_TEXT_DOMAIN), __(\'Add Recipe\', KRM_TEXT_DOMAIN), \'edit_recipe\', \'post-new.php?post_type=recipe\');\n        add_submenu_page(\'krm_ops\', __(\'Settings\', KRM_TEXT_DOMAIN), __(\'Settings\', KRM_TEXT_DOMAIN), \'krm_manage_settings\', \'krm_settings\', [__CLASS__, \'settings_page\']);\n    }\n\n    public static function dashboard() {\n        echo \'<div class="wrap"><h1>Recipe Ops</h1><p>\' . esc_html__(\'Use side menu to manage Ingredients and Recipes.\', KRM_TEXT_DOMAIN) . \'</p></div>\';\n    }\n\n    public static function settings() {\n        register_setting(\'krm_settings\', \'krm_currency\', [\'sanitize_callback\' => \'sanitize_text_field\']);\n        register_setting(\'krm_settings\', \'krm_unit_system\', [\'sanitize_callback\' => \'sanitize_text_field\']);\n        register_setting(\'krm_settings\', \'krm_misc_pct\', [\'sanitize_callback\' => \'absint\']);\n        register_setting(\'krm_settings\', \'krm_cost_color_thresholds\');\n        register_setting(\'krm_settings\', \'krm_allergens_master\');\n\n        add_settings_section(\'krm_main\', __(\'General\', KRM_TEXT_DOMAIN), \'__return_false\', \'krm_settings\');\n\n        add_settings_field(\'currency\', __(\'Currency\', KRM_TEXT_DOMAIN), function() {\n            printf(\'<input type="text" name="krm_currency" value="%s" />\', esc_attr(opt(\'krm_currency\',\'MYR\')));\n        }, \'krm_settings\', \'krm_main\');\n\n        add_settings_field(\'unit_system\', __(\'Unit System\', KRM_TEXT_DOMAIN), function() {\n            $val = opt(\'krm_unit_system\',\'metric\');\n            echo \'<select name="krm_unit_system"><option value="metric" \' . selected($val,\'metric\',false) . \'>metric</option><option value="imperial" \' . selected($val,\'imperial\',false) . \'>imperial</option></select>\';\n        }, \'krm_settings\', \'krm_main\');\n\n        add_settings_field(\'misc\', __(\'Default Misc %\', KRM_TEXT_DOMAIN), function() {\n            printf(\'<input type="number" name="krm_misc_pct" value="%s" step="1" min="0" />\', esc_attr(opt(\'krm_misc_pct\',10)));\n        }, \'krm_settings\', \'krm_main\');\n\n        add_settings_field(\'allergens\', __(\'Allergen Master List\', KRM_TEXT_DOMAIN), function() {\n            $vals = (array) opt(\'krm_allergens_master\', array());\n            printf(\'<textarea name="krm_allergens_master" rows="4" style="width:100%%">%s</textarea>\', esc_textarea(implode(\',\', $vals)));\n            echo \'<p class="description">\' . esc_html__(\'Comma-separated list. Examples: gluten, eggs, milk, peanuts…\', KRM_TEXT_DOMAIN) . \'</p>\';\n        }, \'krm_settings\', \'krm_main\');\n    }\n\n    public static function settings_page() {\n        if (!current_user_can(\'krm_manage_settings\')) { wp_die(__(\'You do not have permission.\', KRM_TEXT_DOMAIN)); }\n        echo \'<div class="wrap"><h1>\'. esc_html__(\'Kyros Recipe Manager Settings\', KRM_TEXT_DOMAIN) .\'</h1>\';\n        echo \'<form method="post" action="options.php">\';\n        settings_fields(\'krm_settings\');\n        do_settings_sections(\'krm_settings\');\n        submit_button();\n        echo \'</form></div>\';\n    }\n}\n'
FILES['includes/class-block.php'] = '<?php\nnamespace Kyros\\RecipeManager;\n\ndefined(\'ABSPATH\') || exit;\n\nclass Block {\n    public static function init() {\n        add_action(\'init\', [__CLASS__, \'register_block\']);\n    }\n\n    public static function register_block() {\n        // Minimal dynamic block that reuses shortcode render\n        register_block_type_from_metadata(KRM_PATH . \'includes\', array(\n            \'render_callback\' => function($atts) {\n                $id = isset($atts[\'recipeId\']) ? intval($atts[\'recipeId\']) : 0;\n                return do_shortcode(\'[recipe_calculator id="\' . $id . \'"]\');\n            }\n        ));\n        wp_register_script(\'krm-block\', KRM_URL . \'assets/js/block.js\', array(\'wp-blocks\',\'wp-element\',\'wp-editor\'), KRM_VERSION, true);\n        wp_set_script_translations(\'krm-block\', KRM_TEXT_DOMAIN, KRM_PATH . \'languages\');\n    }\n}\n'
FILES['includes/class-calculator.php'] = "<?php\nnamespace Kyros\\RecipeManager;\n\ndefined('ABSPATH') || exit;\n\n/** Lightweight calculator utilities */\nclass Calculator {\n    /** Row subtotal: qty * unit_cost * (1 + waste/100) */\n    public static function row_subtotal(float $qty, float $unit_cost, float $waste_pct = 0.0): float {\n        return round((float)$qty * (float)$unit_cost * (1 + ((float)$waste_pct/100)), 4);\n    }\n\n    public static function total(array $rows): float {\n        $t = 0.0;\n        foreach ($rows as $r) { $t += self::row_subtotal((float)($r['quantity']??0), (float)($r['unit_cost']??0), (float)($r['waste_pct']??0)); }\n        return round($t, 4);\n    }\n\n    public static function misc_amount(float $total, float $misc_pct): float {\n        return round($total * ((float)$misc_pct/100), 4);\n    }\n\n    public static function cost_percent(float $total, float $selling): float {\n        if ($selling <= 0) return 0.0;\n        return round(($total / $selling) * 100, 2);\n    }\n}\n"
FILES['includes/class-cpt-ingredient.php'] = "<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class CPT_Ingredient {
    public static function init() {
        add_action('init', [__CLASS__, 'register']);
        add_action('add_meta_boxes', [__CLASS__, 'metaboxes']);
        add_action('save_post', [__CLASS__, 'save'], 10, 2);
        add_filter('manage_ingredient_posts_columns', [__CLASS__, 'cols']);
        add_action('manage_ingredient_posts_custom_column', [__CLASS__, 'col_content'], 10, 2);
    }

    public static function register() {
        register_post_type('ingredient', array(
            'labels' => array(
                'name' => __('Ingredients', KRM_TEXT_DOMAIN),
                'singular_name' => __('Ingredient', KRM_TEXT_DOMAIN),
            ),
            'public' => false,
            'show_ui' => true,
            'capability_type' => 'ingredient',
            'map_meta_cap' => true,
            'supports' => array('title'),
            'show_in_menu' => 'krm_ops',
            'menu_icon' => 'dashicons-carrot',
        ));
    }

    public static function metaboxes() {
        add_meta_box('krm_ing_meta', __('Ingredient Details', KRM_TEXT_DOMAIN), [__CLASS__, 'box'], 'ingredient', 'normal', 'default');
    }

    public static function box($post) {
        wp_nonce_field('krm_ing_save', 'krm_ing_nonce');
        $unit_base = get_post_meta($post->ID, 'krm_unit_base', true) ?: 'kg';
        $weight_base = get_post_meta($post->ID, 'krm_weight_base', true) ?: '1';
        $price_per_base = get_post_meta($post->ID, 'krm_price_per_base', true) ?: '0';
        $supplier_name = get_post_meta($post->ID, 'krm_supplier_name', true);
        $supplier_contact = get_post_meta($post->ID, 'krm_supplier_contact', true);
        $family = get_post_meta($post->ID, 'krm_measurement_family', true) ?: 'mass';
        $density = get_post_meta($post->ID, 'krm_density', true);
        $allergens_master = opt('krm_allergens_master', array());
        $allergens = (array) get_post_meta($post->ID, 'krm_allergens', true);
        ?>
        <table class=\"form-table\">
            <tr><th><?php _e('Measurement Family', KRM_TEXT_DOMAIN); ?></th>
                <td>
                    <select name=\"krm_measurement_family\">
                        <option value=\"mass\" <?php selected($family, 'mass'); ?>>mass (g/kg)</option>
                        <option value=\"volume\" <?php selected($family, 'volume'); ?>>volume (ml/L)</option>
                        <option value=\"piece\" <?php selected($family, 'piece'); ?>>piece</option>
                    </select>
                    <p class=\"description\"><?php _e('Choose how this ingredient is measured.', KRM_TEXT_DOMAIN); ?></p>
                </td></tr>
            <tr><th><?php _e('Base Unit', KRM_TEXT_DOMAIN); ?></th>
                <td>
                    <input type=\"text\" name=\"krm_unit_base\" value=\"<?php echo esc_attr($unit_base); ?>\" />
                    <span class=\"description\"><?php _e('kg, L, piece …', KRM_TEXT_DOMAIN); ?></span>
                </td></tr>
            <tr><th><?php _e('Base Weight/Volume', KRM_TEXT_DOMAIN); ?></th>
                <td><input type=\"number\" step=\"0.0001\" name=\"krm_weight_base\" value=\"<?php echo esc_attr($weight_base); ?>\" /></td></tr>
            <tr><th><?php _e('Price per Base Unit (RM)', KRM_TEXT_DOMAIN); ?></th>
                <td><input type=\"number\" step=\"0.0001\" name=\"krm_price_per_base\" value=\"<?php echo esc_attr($price_per_base); ?>\" /></td></tr>
            <tr><th><?php _e('Density (g/ml, optional)', KRM_TEXT_DOMAIN); ?></th>
                <td><input type=\"number\" step=\"0.0001\" name=\"krm_density\" value=\"<?php echo esc_attr($density); ?>\" /></td></tr>
            <tr><th><?php _e('Supplier', KRM_TEXT_DOMAIN); ?></th>
                <td><input type=\"text\" name=\"krm_supplier_name\" value=\"<?php echo esc_attr($supplier_name); ?>\" />
                <input type=\"text\" name=\"krm_supplier_contact\" value=\"<?php echo esc_attr($supplier_contact); ?>\" placeholder=\"phone/email\" /></td></tr>
            <tr><th><?php _e('Allergens', KRM_TEXT_DOMAIN); ?></th>
                <td>
                    <?php foreach ($allergens_master as $a): ?>
                      <label style=\"display:inline-block;margin-right:10px;\"><input type=\"checkbox\" name=\"krm_allergens[]\" value=\"<?php echo esc_attr($a); ?>\" <?php checked(in_array($a, $allergens, true)); ?> /> <?php echo esc_html($a); ?></label>
                    <?php endforeach; ?>
                </td>
            </tr>
        </table>
        <?php
    }

    public static function save($post_id, $post) {
        if ($post->post_type !== 'ingredient') {
            return;
        }
        if (!isset($_POST['krm_ing_nonce']) || !wp_verify_nonce($_POST['krm_ing_nonce'], 'krm_ing_save')) {
            return;
        }
        if (!current_user_can('edit_post', $post_id)) {
            return;
        }

        $fields = array('unit_base', 'weight_base', 'price_per_base', 'supplier_name', 'supplier_contact', 'measurement_family', 'density');
        foreach ($fields as $f) {
            $key = 'krm_' . $f;
            $val = isset($_POST[$key]) ? sanitize_text_field($_POST[$key]) : '';
            update_post_meta($post_id, $key, $val);
        }
        $allergens = isset($_POST['krm_allergens']) ? array_map('sanitize_text_field', (array) $_POST['krm_allergens']) : array();
        update_post_meta($post_id, 'krm_allergens', $allergens);
    }

    public static function cols($cols) {
        $ordered = array();
        if (isset($cols['cb'])) {
            $ordered['cb'] = $cols['cb'];
        }
        $ordered['title'] = __('Product', KRM_TEXT_DOMAIN);
        $ordered['krm_base'] = __('Base & Price', KRM_TEXT_DOMAIN);
        $ordered['krm_supplier'] = __('Supplier', KRM_TEXT_DOMAIN);
        $ordered['krm_allergens'] = __('Allergens', KRM_TEXT_DOMAIN);
        $ordered['krm_actions'] = __('Actions', KRM_TEXT_DOMAIN);
        if (isset($cols['date'])) {
            $ordered['date'] = $cols['date'];
        }
        return $ordered;
    }

    public static function col_content($col, $post_id) {
        if ('krm_base' === $col) {
            $u = get_post_meta($post_id, 'krm_unit_base', true);
            $w = get_post_meta($post_id, 'krm_weight_base', true);
            $p = get_post_meta($post_id, 'krm_price_per_base', true);
            echo esc_html(\"{$w} {$u} @ RM {$p}\");
        } elseif ('krm_supplier' === $col) {
            echo esc_html(get_post_meta($post_id, 'krm_supplier_name', true));
        } elseif ('krm_allergens' === $col) {
            echo esc_html(implode(', ', (array) get_post_meta($post_id, 'krm_allergens', true)));
        } elseif ('krm_actions' === $col) {
            $edit = get_edit_post_link($post_id);
            if ($edit) {
                echo '<a class=\"button button-small\" href=\"' . esc_url($edit) . '\">' . esc_html__('Edit', KRM_TEXT_DOMAIN) . '</a>';
            }
        }
    }
}
"ABSPATH\') || exit;\n\nclass CPT_Ingredient {\n    public static function init() {\n        add_action(\'init\', [__CLASS__, \'register\']);\n        add_action(\'add_meta_boxes\', [__CLASS__, \'metaboxes\']);\n        add_action(\'save_post\', [__CLASS__, \'save\'], 10, 2);\n        add_filter(\'manage_ingredient_posts_columns\', [__CLASS__, \'cols\']);\n        add_action(\'manage_ingredient_posts_custom_column\', [__CLASS__, \'col_content\'], 10, 2);\n    }\n\n    public static function register() {\n        register_post_type(\'ingredient\', array(\n            \'labels\' => array(\n                \'name\' => __(\'Ingredients\', KRM_TEXT_DOMAIN),\n                \'singular_name\' => __(\'Ingredient\', KRM_TEXT_DOMAIN),\n            ),\n            \'public\' => false,\n            \'show_ui\' => true,\n            \'show_in_menu\' => \'krm_ops\',\n            \'show_in_admin_bar\' => false,\n            \'capability_type\' => \'ingredient\',\n            \'map_meta_cap\' => true,\n            \'supports\' => array(\'title\'),\n            \'menu_icon\' => \'dashicons-carrot\',\n        ));\n    }\n\n    public static function metaboxes() {\n        add_meta_box(\'krm_ing_meta\', __(\'Ingredient Details\', KRM_TEXT_DOMAIN), [__CLASS__, \'box\'], \'ingredient\', \'normal\', \'default\');\n    }\n\n    public static function box($post) {\n        wp_nonce_field(\'krm_ing_save\', \'krm_ing_nonce\');\n        $unit_base = get_post_meta($post->ID, \'krm_unit_base\', true) ?: \'kg\';\n        $weight_base = get_post_meta($post->ID, \'krm_weight_base\', true) ?: \'1\';\n        $price_per_base = get_post_meta($post->ID, \'krm_price_per_base\', true) ?: \'0\';\n        $supplier_name = get_post_meta($post->ID, \'krm_supplier_name\', true);\n        $supplier_contact = get_post_meta($post->ID, \'krm_supplier_contact\', true);\n        $family = get_post_meta($post->ID, \'krm_measurement_family\', true) ?: \'mass\'; // mass|volume|piece\n        $density = get_post_meta($post->ID, \'krm_density\', true); // g/ml optional\n        $allergens_master = opt(\'krm_allergens_master\', array());\n        $allergens = (array) get_post_meta($post->ID, \'krm_allergens\', true);\n        ?>\n        <table class="form-table">\n            <tr><th><?php _e(\'Measurement Family\', KRM_TEXT_DOMAIN); ?></th>\n                <td>\n                    <select name="krm_measurement_family">\n                        <option value="mass" <?php selected($family,\'mass\'); ?>>mass (g/kg)</option>\n                        <option value="volume" <?php selected($family,\'volume\'); ?>>volume (ml/L)</option>\n                        <option value="piece" <?php selected($family,\'piece\'); ?>>piece</option>\n                    </select>\n                    <p class="description"><?php _e(\'Choose how this ingredient is measured.\', KRM_TEXT_DOMAIN); ?></p>\n                </td></tr>\n            <tr><th><?php _e(\'Base Unit\', KRM_TEXT_DOMAIN); ?></th>\n                <td>\n                    <input type="text" name="krm_unit_base" value="<?php echo esc_attr($unit_base); ?>" />\n                    <span class="description"><?php _e(\'kg, L, piece …\', KRM_TEXT_DOMAIN); ?></span>\n                </td></tr>\n            <tr><th><?php _e(\'Base Weight/Volume\', KRM_TEXT_DOMAIN); ?></th>\n                <td><input type="number" step="0.0001" name="krm_weight_base" value="<?php echo esc_attr($weight_base); ?>" /></td></tr>\n            <tr><th><?php _e(\'Price per Base Unit (RM)\', KRM_TEXT_DOMAIN); ?></th>\n                <td><input type="number" step="0.0001" name="krm_price_per_base" value="<?php echo esc_attr($price_per_base); ?>" /></td></tr>\n            <tr><th><?php _e(\'Density (g/ml, optional)\', KRM_TEXT_DOMAIN); ?></th>\n                <td><input type="number" step="0.0001" name="krm_density" value="<?php echo esc_attr($density); ?>" /></td></tr>\n            <tr><th><?php _e(\'Supplier\', KRM_TEXT_DOMAIN); ?></th>\n                <td><input type="text" name="krm_supplier_name" value="<?php echo esc_attr($supplier_name); ?>" />\n                <input type="text" name="krm_supplier_contact" value="<?php echo esc_attr($supplier_contact); ?>" placeholder="phone/email" /></td></tr>\n            <tr><th><?php _e(\'Allergens\', KRM_TEXT_DOMAIN); ?></th>\n                <td>\n                    <?php foreach ($allergens_master as $a): ?>\n                      <label style="display:inline-block;margin-right:10px;"><input type="checkbox" name="krm_allergens[]" value="<?php echo esc_attr($a); ?>" <?php checked(in_array($a,$allergens,true)); ?> /> <?php echo esc_html($a); ?></label>\n                    <?php endforeach; ?>\n                </td>\n            </tr>\n        </table>\n        <?php\n    }\n\n    public static function save($post_id, $post) {\n        if ($post->post_type !== \'ingredient\') return;\n        if (!isset($_POST[\'krm_ing_nonce\']) || !wp_verify_nonce($_POST[\'krm_ing_nonce\'],\'krm_ing_save\')) return;\n        if (!current_user_can(\'edit_post\', $post_id)) return;\n\n        $fields = array(\'unit_base\',\'weight_base\',\'price_per_base\',\'supplier_name\',\'supplier_contact\',\'measurement_family\',\'density\');\n        foreach ($fields as $f) {\n            $key = \'krm_\' . $f;\n            $val = isset($_POST[$key]) ? sanitize_text_field($_POST[$key]) : \'\';\n            update_post_meta($post_id, $key, $val);\n        }\n        $allergens = isset($_POST[\'krm_allergens\']) ? array_map(\'sanitize_text_field\', (array)$_POST[\'krm_allergens\']) : array();\n        update_post_meta($post_id, \'krm_allergens\', $allergens);\n    }\n\n    public static function cols($cols) {\n        $new = array(\n            \'title\' => __(\'Product\', KRM_TEXT_DOMAIN),\n            \'krm_base\' => __(\'Base & Price\', KRM_TEXT_DOMAIN),\n            \'krm_supplier\' => __(\'Supplier\', KRM_TEXT_DOMAIN),\n            \'krm_allergens\' => __(\'Allergens\', KRM_TEXT_DOMAIN),\n        );\n        return $new + $cols;\n    }\n\n    public static function col_content($col, $post_id) {\n        if (\'krm_base\' === $col) {\n            $u = get_post_meta($post_id, \'krm_unit_base\', true);\n            $w = get_post_meta($post_id, \'krm_weight_base\', true);\n            $p = get_post_meta($post_id, \'krm_price_per_base\', true);\n            echo esc_html("{$w} {$u} @ RM {$p}");\n        } elseif (\'krm_supplier\' === $col) {\n            echo esc_html(get_post_meta($post_id, \'krm_supplier_name\', true));\n        } elseif (\'krm_allergens\' === $col) {\n            echo esc_html(implode(\',\', (array) get_post_meta($post_id, \'krm_allergens\', true)));\n        }\n    }\n}\n'
FILES['includes/class-cpt-recipe.php'] = "<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class CPT_Recipe {
    public static function init() {
        add_action('init', [__CLASS__, 'register']);
        add_action('add_meta_boxes', [__CLASS__, 'metaboxes']);
        add_action('save_post', [__CLASS__, 'save'], 10, 2);
        add_filter('manage_recipe_posts_columns', [__CLASS__, 'cols']);
        add_action('manage_recipe_posts_custom_column', [__CLASS__, 'col_content'], 10, 2);
    }

    public static function register() {
        register_post_type('recipe', array(
            'labels' => array(
                'name' => __('Recipes', KRM_TEXT_DOMAIN),
                'singular_name' => __('Recipe', KRM_TEXT_DOMAIN),
            ),
            'public' => false,
            'show_ui' => true,
            'capability_type' => 'recipe',
            'map_meta_cap' => true,
            'supports' => array('title', 'thumbnail'),
            'show_in_menu' => 'krm_ops',
            'menu_icon' => 'dashicons-clipboard',
        ));
    }

    public static function metaboxes() {
        add_meta_box('krm_recipe_meta', __('Recipe Quick Facts', KRM_TEXT_DOMAIN), [__CLASS__, 'box_quick'], 'recipe', 'normal', 'high');
        add_meta_box('krm_recipe_dirs', __('Directions', KRM_TEXT_DOMAIN), [__CLASS__, 'box_dirs'], 'recipe', 'normal', 'default');
        add_meta_box('krm_recipe_ing', __('Ingredients Used', KRM_TEXT_DOMAIN), [__CLASS__, 'box_ing'], 'recipe', 'normal', 'default');
    }

    public static function box_quick($post) {
        wp_nonce_field('krm_recipe_save', 'krm_recipe_nonce');
        $servings = get_post_meta($post->ID, 'krm_servings', true) ?: 1;
        $yield_unit = get_post_meta($post->ID, 'krm_yield_unit', true) ?: 'portion';
        $wastage = get_post_meta($post->ID, 'krm_wastage_pct', true) ?: 0;
        $prep = get_post_meta($post->ID, 'krm_prep_time', true) ?: 0;
        $status = get_post_meta($post->ID, 'krm_status', true) ?: 'draft';
        ?>
        <table class=\"form-table\">
          <tr><th><?php _e('Servings', KRM_TEXT_DOMAIN); ?></th><td><input type=\"number\" name=\"krm_servings\" value=\"<?php echo esc_attr($servings); ?>\" /></td></tr>
          <tr><th><?php _e('Yield Unit', KRM_TEXT_DOMAIN); ?></th><td><input type=\"text\" name=\"krm_yield_unit\" value=\"<?php echo esc_attr($yield_unit); ?>\" /></td></tr>
          <tr><th><?php _e('Wastage %', KRM_TEXT_DOMAIN); ?></th><td><input type=\"number\" step=\"0.01\" name=\"krm_wastage_pct\" value=\"<?php echo esc_attr($wastage); ?>\" /></td></tr>
          <tr><th><?php _e('Prep Time (min)', KRM_TEXT_DOMAIN); ?></th><td><input type=\"number\" name=\"krm_prep_time\" value=\"<?php echo esc_attr($prep); ?>\" /></td></tr>
          <tr><th><?php _e('Status', KRM_TEXT_DOMAIN); ?></th>
          <td>
            <select name=\"krm_status\">
              <option value=\"draft\" <?php selected($status, 'draft'); ?>>Draft</option>
              <option value=\"pending\" <?php selected($status, 'pending'); ?>>Pending Approval</option>
              <option value=\"use\" <?php selected($status, 'use'); ?>>Use</option>
              <option value=\"not_used\" <?php selected($status, 'not_used'); ?>>Not used</option>
              <option value=\"stop\" <?php selected($status, 'stop'); ?>>Stop production</option>
            </select>
            <a class=\"button\" href=\"<?php echo esc_url(get_permalink($post->ID)); ?>\" target=\"_blank\"><?php _e('View SOP/Calculator', KRM_TEXT_DOMAIN); ?></a>
          </td></tr>
        </table>
        <?php
    }

    public static function box_dirs($post) {
        $dirs = (array) get_post_meta($post->ID, 'krm_directions', true);
        echo '<p class=\"description\">' . esc_html__('Add cooking directions. One per row.', KRM_TEXT_DOMAIN) . '</p>';
        echo '<table class=\"widefat fixed\"><thead><tr><th>#</th><th>' . esc_html__('Instruction', KRM_TEXT_DOMAIN) . '</th></tr></thead><tbody id=\"krm-dirs-body\">';
        if (empty($dirs)) {
            $dirs = array(array('step_no' => 1, 'instruction' => ''));
        }
        foreach ($dirs as $i => $row) {
            $n = intval($row['step_no'] ?? $i + 1);
            $t = esc_textarea($row['instruction'] ?? '');
            echo '<tr><td><input type=\"number\" name=\"krm_dirs[' . $i . '][step_no]\" value=\"' . $n . '\" /></td><td><textarea name=\"krm_dirs[' . $i . '][instruction]\" rows=\"2\" style=\"width:100%\">' . $t . '</textarea></td></tr>';
        }
        echo '</tbody></table><p><button type=\"button\" class=\"button\" id=\"krm-add-dir\">+ ' . esc_html__('Add Step', KRM_TEXT_DOMAIN) . '</button></p>';
    }

    public static function box_ing($post) {
        echo '<p class=\"description\">' . esc_html__('Manage ingredient rows in the front-end calculator or here (MVP keeps it in front-end).', KRM_TEXT_DOMAIN) . '</p>';
        echo '<p><em>' . esc_html__('Use the front-end to add ingredients and click “Save Menu” to persist line items.', KRM_TEXT_DOMAIN) . '</em></p>';
    }

    public static function save($post_id, $post) {
        if ($post->post_type !== 'recipe') {
            return;
        }
        if (!isset($_POST['krm_recipe_nonce']) || !wp_verify_nonce($_POST['krm_recipe_nonce'], 'krm_recipe_save')) {
            return;
        }
        if (!current_user_can('edit_post', $post_id)) {
            return;
        }

        $fields = array('servings', 'yield_unit', 'wastage_pct', 'prep_time', 'status');
        foreach ($fields as $f) {
            $key = 'krm_' . $f;
            $val = isset($_POST[$key]) ? sanitize_text_field($_POST[$key]) : '';
            update_post_meta($post_id, $key, $val);
        }
        if (isset($_POST['krm_dirs'])) {
            $rows = array();
            foreach ((array) $_POST['krm_dirs'] as $r) {
                $rows[] = array(
                    'step_no' => intval($r['step_no'] ?? 0),
                    'instruction' => wp_kses_post($r['instruction'] ?? '')
                );
            }
            update_post_meta($post_id, 'krm_directions', $rows);
        }
    }

    public static function cols($cols) {
        $ordered = array();
        if (isset($cols['cb'])) {
            $ordered['cb'] = $cols['cb'];
        }
        $ordered['title'] = __('Recipe', KRM_TEXT_DOMAIN);
        $ordered['krm_servings'] = __('Servings', KRM_TEXT_DOMAIN);
        $ordered['krm_status'] = __('Status', KRM_TEXT_DOMAIN);
        $ordered['krm_actions'] = __('Actions', KRM_TEXT_DOMAIN);
        if (isset($cols['date'])) {
            $ordered['date'] = $cols['date'];
        }
        return $ordered;
    }

    public static function col_content($col, $post_id) {
        if ('krm_servings' === $col) {
            $servings = get_post_meta($post_id, 'krm_servings', true);
            $unit = get_post_meta($post_id, 'krm_yield_unit', true);
            echo esc_html(trim($servings . ' ' . $unit));
        } elseif ('krm_status' === $col) {
            $status = get_post_meta($post_id, 'krm_status', true);
            echo esc_html(ucfirst($status ?: 'draft'));
        } elseif ('krm_actions' === $col) {
            $edit = get_edit_post_link($post_id);
            if ($edit) {
                echo '<a class=\"button button-small\" href=\"' . esc_url($edit) . '\">' . esc_html__('Edit', KRM_TEXT_DOMAIN) . '</a>';
            }
        }
    }
}
"ABSPATH\') || exit;\n\nclass CPT_Recipe {\n    public static function init() {\n        add_action(\'init\', [__CLASS__, \'register\']);\n        add_action(\'add_meta_boxes\', [__CLASS__, \'metaboxes\']);\n        add_action(\'save_post\', [__CLASS__, \'save\'], 10, 2);\n    }\n\n    public static function register() {\n        register_post_type(\'recipe\', array(\n            \'labels\' => array(\n                \'name\' => __(\'Recipes\', KRM_TEXT_DOMAIN),\n                \'singular_name\' => __(\'Recipe\', KRM_TEXT_DOMAIN),\n            ),\n            \'public\' => false,\n            \'show_ui\' => true,\n            \'show_in_menu\' => \'krm_ops\',\n            \'show_in_admin_bar\' => false,\n            \'capability_type\' => \'recipe\',\n            \'map_meta_cap\' => true,\n            \'supports\' => array(\'title\', \'thumbnail\'),\n            \'menu_icon\' => \'dashicons-clipboard\',\n        ));\n    }\n\n    public static function metaboxes() {\n        add_meta_box(\'krm_recipe_meta\', __(\'Recipe Quick Facts\', KRM_TEXT_DOMAIN), [__CLASS__, \'box_quick\'], \'recipe\', \'normal\', \'high\');\n        add_meta_box(\'krm_recipe_dirs\', __(\'Directions\', KRM_TEXT_DOMAIN), [__CLASS__, \'box_dirs\'], \'recipe\', \'normal\', \'default\');\n        add_meta_box(\'krm_recipe_ing\', __(\'Ingredients Used\', KRM_TEXT_DOMAIN), [__CLASS__, \'box_ing\'], \'recipe\', \'normal\', \'default\');\n    }\n\n    public static function box_quick($post) {\n        wp_nonce_field(\'krm_recipe_save\',\'krm_recipe_nonce\');\n        $servings = get_post_meta($post->ID, \'krm_servings\', true) ?: 1;\n        $yield_unit = get_post_meta($post->ID, \'krm_yield_unit\', true) ?: \'portion\';\n        $wastage = get_post_meta($post->ID, \'krm_wastage_pct\', true) ?: 0;\n        $prep = get_post_meta($post->ID, \'krm_prep_time\', true) ?: 0;\n        $status = get_post_meta($post->ID, \'krm_status\', true) ?: \'draft\'; // draft|pending|use|not_used|stop\n        ?>\n        <table class="form-table">\n          <tr><th><?php _e(\'Servings\', KRM_TEXT_DOMAIN); ?></th><td><input type="number" name="krm_servings" value="<?php echo esc_attr($servings); ?>" /></td></tr>\n          <tr><th><?php _e(\'Yield Unit\', KRM_TEXT_DOMAIN); ?></th><td><input type="text" name="krm_yield_unit" value="<?php echo esc_attr($yield_unit); ?>" /></td></tr>\n          <tr><th><?php _e(\'Wastage %\', KRM_TEXT_DOMAIN); ?></th><td><input type="number" step="0.01" name="krm_wastage_pct" value="<?php echo esc_attr($wastage); ?>" /></td></tr>\n          <tr><th><?php _e(\'Prep Time (min)\', KRM_TEXT_DOMAIN); ?></th><td><input type="number" name="krm_prep_time" value="<?php echo esc_attr($prep); ?>" /></td></tr>\n          <tr><th><?php _e(\'Status\', KRM_TEXT_DOMAIN); ?></th>\n          <td>\n            <select name="krm_status">\n              <option value="draft" <?php selected($status,\'draft\'); ?>>Draft</option>\n              <option value="pending" <?php selected($status,\'pending\'); ?>>Pending Approval</option>\n              <option value="use" <?php selected($status,\'use\'); ?>>Use</option>\n              <option value="not_used" <?php selected($status,\'not_used\'); ?>>Not used</option>\n              <option value="stop" <?php selected($status,\'stop\'); ?>>Stop production</option>\n            </select>\n            <a class="button" href="<?php echo esc_url(get_permalink($post->ID)); ?>" target="_blank"><?php _e(\'View SOP/Calculator\', KRM_TEXT_DOMAIN); ?></a>\n          </td></tr>\n        </table>\n        <?php\n    }\n\n    public static function box_dirs($post) {\n        $dirs = (array) get_post_meta($post->ID, \'krm_directions\', true);\n        echo \'<p class="description">\' . esc_html__(\'Add cooking directions. One per row.\', KRM_TEXT_DOMAIN) . \'</p>\';\n        echo \'<table class="widefat fixed"><thead><tr><th>#</th><th>\' . esc_html__(\'Instruction\', KRM_TEXT_DOMAIN) . \'</th></tr></thead><tbody id="krm-dirs-body">\';\n        if (empty($dirs)) { $dirs = array(array(\'step_no\'=>1,\'instruction\'=>\'\')); }\n        foreach ($dirs as $i => $row) {\n            $n = intval($row[\'step_no\'] ?? $i+1);\n            $t = esc_textarea($row[\'instruction\'] ?? \'\');\n            echo \'<tr><td><input type="number" name="krm_dirs[\'.$i.\'][step_no]" value="\'.$n.\'" /></td><td><textarea name="krm_dirs[\'.$i.\'][instruction]" rows="2" style="width:100%">\'.$t.\'</textarea></td></tr>\';\n        }\n        echo \'</tbody></table><p><button type="button" class="button" id="krm-add-dir">+ \' . esc_html__(\'Add Step\', KRM_TEXT_DOMAIN) . \'</button></p>\';\n    }\n\n    public static function box_ing($post) {\n        echo \'<p class="description">\' . esc_html__(\'Manage ingredient rows in the front-end calculator or here (MVP keeps it in front-end).\', KRM_TEXT_DOMAIN) . \'</p>\';\n        echo \'<p><em>\' . esc_html__(\'Use the front-end to add ingredients and click “Save Menu” to persist line items.\', KRM_TEXT_DOMAIN) . \'</em></p>\';\n    }\n\n    public static function save($post_id, $post) {\n        if ($post->post_type !== \'recipe\') return;\n        if (!isset($_POST[\'krm_recipe_nonce\']) || !wp_verify_nonce($_POST[\'krm_recipe_nonce\'],\'krm_recipe_save\')) return;\n        if (!current_user_can(\'edit_post\', $post_id)) return;\n\n        $fields = array(\'servings\',\'yield_unit\',\'wastage_pct\',\'prep_time\',\'status\');\n        foreach ($fields as $f) {\n            $key = \'krm_\' . $f;\n            $val = isset($_POST[$key]) ? sanitize_text_field($_POST[$key]) : \'\';\n            update_post_meta($post_id, $key, $val);\n        }\n        // Directions\n        if (isset($_POST[\'krm_dirs\'])) {\n            $rows = array();\n            foreach ((array)$_POST[\'krm_dirs\'] as $r) {\n                $rows[] = array(\n                    \'step_no\' => intval($r[\'step_no\'] ?? 0),\n                    \'instruction\' => wp_kses_post($r[\'instruction\'] ?? \'\')\n                );\n            }\n            update_post_meta($post_id, \'krm_directions\', $rows);\n        }\n    }\n}\n'
FILES['includes/class-db.php'] = '<?php\nnamespace Kyros\\RecipeManager;\n\ndefined(\'ABSPATH\') || exit;\n\nclass DB {\n    public static function table_items() {\n        global $wpdb;\n        return $wpdb->prefix . \'krm_recipe_items\';\n    }\n\n    public static function maybe_install() {\n        global $wpdb;\n        $table = self::table_items();\n        $charset_collate = $wpdb->get_charset_collate();\n        $version = get_option(\'krm_db_version\');\n\n        $sql = "CREATE TABLE $table (\n            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,\n            recipe_post_id BIGINT UNSIGNED NOT NULL,\n            ingredient_post_id BIGINT UNSIGNED NOT NULL,\n            quantity DECIMAL(12,4) NOT NULL DEFAULT 0,\n            unit VARCHAR(50) NOT NULL DEFAULT \'\',\n            waste_pct DECIMAL(5,2) NOT NULL DEFAULT 0,\n            cost_snapshot DECIMAL(12,4) NOT NULL DEFAULT 0,\n            created_at DATETIME NULL,\n            updated_at DATETIME NULL,\n            PRIMARY KEY  (id),\n            KEY recipe_post_id (recipe_post_id),\n            KEY ingredient_post_id (ingredient_post_id)\n        ) $charset_collate;";\n\n        require_once ABSPATH . \'wp-admin/includes/upgrade.php\';\n        dbDelta($sql);\n        if ($version !== \'1\') {\n            update_option(\'krm_db_version\',\'1\');\n        }\n    }\n\n    public static function items_for_recipe(int $recipe_id): array {\n        global $wpdb;\n        return $wpdb->get_results($wpdb->prepare("SELECT * FROM " . self::table_items() . " WHERE recipe_post_id=%d ORDER BY id ASC", $recipe_id), ARRAY_A) ?: array();\n    }\n}\n'
FILES['includes/class-export.php'] = "<?php\nnamespace Kyros\\RecipeManager;\n\ndefined('ABSPATH') || exit;\n\nclass Export {\n    public static function sop_link(int $recipe_id): string {\n        return add_query_arg(array('krm_sop' => $recipe_id), home_url('/'));\n    }\n}\n"
FILES['includes/class-notify.php'] = "<?php\nnamespace Kyros\\RecipeManager;\n\ndefined('ABSPATH') || exit;\n\nclass Notify {\n    // Placeholder for mention-user via email in future versions.\n}\n"
FILES['includes/class-plugin.php'] = "<?php
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
"
FILES['includes/class-roles.php'] = "<?php\nnamespace Kyros\\RecipeManager;\n\ndefined('ABSPATH') || exit;\n\nclass Roles {\n    public static function add_roles() {\n        add_role('krm_admin', 'KRM Admin', array('read' => true, 'manage_options' => true));\n        add_role('krm_operation', 'KRM Operation', array('read' => true));\n        add_role('krm_supervisor', 'KRM Supervisor', array('read' => true));\n    }\n\n    public static function remove_roles() {\n        remove_role('krm_admin');\n        remove_role('krm_operation');\n        remove_role('krm_supervisor');\n    }\n\n    public static function add_caps() {\n        $caps = array(\n            'read_ingredient','edit_ingredient','edit_ingredients','publish_ingredients','delete_ingredient',\n            'read_recipe','edit_recipe','edit_recipes','publish_recipes','delete_recipe',\n            'krm_manage_settings','krm_export_pdf','krm_mention_user','krm_approve_recipe'\n        );\n\n        if ($role = get_role('administrator')) foreach ($caps as $c) { $role->add_cap($c); }\n        if ($role = get_role('krm_admin'))     foreach ($caps as $c) { $role->add_cap($c); }\n        if ($role = get_role('krm_operation')) {\n            foreach (array('read_ingredient','edit_ingredient','edit_ingredients','publish_ingredients','delete_ingredient','read_recipe','edit_recipe','edit_recipes','publish_recipes') as $c) {\n                $role->add_cap($c);\n            }\n        }\n        if ($role = get_role('krm_supervisor')) {\n            foreach (array('read_ingredient','read_recipe') as $c) { $role->add_cap($c); }\n        }\n    }\n\n    public static function remove_caps() {\n        $all_roles = array('administrator','krm_admin','krm_operation','krm_supervisor');\n        $caps = array(\n            'read_ingredient','edit_ingredient','edit_ingredients','publish_ingredients','delete_ingredient',\n            'read_recipe','edit_recipe','edit_recipes','publish_recipes','delete_recipe',\n            'krm_manage_settings','krm_export_pdf','krm_mention_user','krm_approve_recipe'\n        );\n        foreach ($all_roles as $r) {\n            if ($role = get_role($r)) { foreach ($caps as $c) { $role->remove_cap($c); } }\n        }\n    }\n}\n"
FILES['includes/class-shortcode.php'] = "<?php\nnamespace Kyros\\RecipeManager;\n\ndefined('ABSPATH') || exit;\n\nclass Shortcode {\n    public static function init() {\n        add_shortcode('recipe_calculator', [__CLASS__, 'render']);\n        add_action('wp_ajax_krm_save_menu', [__CLASS__, 'save_menu']);\n        add_action('wp_ajax_nopriv_krm_save_menu', '__return_false');\n    }\n\n    public static function render($atts = array(), $content = '') {\n        wp_enqueue_style('krm-frontend');\n        wp_enqueue_style('krm-print');\n        wp_enqueue_script('krm-frontend');\n        $atts = shortcode_atts(array('id' => 0), $atts, 'recipe_calculator');\n        $recipe_id = absint($atts['id']);\n        ob_start();\n        include KRM_PATH . 'templates/frontend-calculator.php';\n        return ob_get_clean();\n    }\n\n    public static function save_menu() {\n        check_ajax_referer('krm_nonce','nonce');\n        if (!current_user_can('edit_recipes')) wp_send_json_error('no_permission', 403);\n\n        $recipe_id = absint($_POST['recipe_id'] ?? 0);\n        $rows = (array) ($_POST['rows'] ?? array());\n        if (!$recipe_id || empty($rows)) wp_send_json_error('invalid', 400);\n\n        global $wpdb;\n        $table = DB::table_items();\n        // wipe then insert (MVP)\n        $wpdb->delete($table, array('recipe_post_id' => $recipe_id));\n        foreach ($rows as $r) {\n            $wpdb->insert($table, array(\n                'recipe_post_id' => $recipe_id,\n                'ingredient_post_id' => absint($r['ingredient_id'] ?? 0),\n                'quantity' => (float) ($r['quantity'] ?? 0),\n                'unit' => sanitize_text_field($r['unit'] ?? ''),\n                'waste_pct' => (float) ($r['waste_pct'] ?? 0),\n                'cost_snapshot' => (float) ($r['unit_cost'] ?? 0),\n                'created_at' => current_time('mysql'),\n                'updated_at' => current_time('mysql'),\n            ));\n        }\n        wp_send_json_success(array('ok' => true));\n    }\n}\n"
FILES['includes/helpers.php'] = "<?php\nnamespace Kyros\\RecipeManager;\n\ndefined('ABSPATH') || exit;\n\n/** Safe option getter with default */\nfunction opt(string $key, $default = null) {\n    $val = get_option($key, null);\n    return (null === $val) ? $default : $val;\n}\n\n/** Currency formatting (MYR default) */\nfunction money($amount): string {\n    $cur = opt('krm_currency', 'MYR');\n    return sprintf('%s %s', esc_html($cur), number_format((float)$amount, 2, '.', ','));\n}\n\n/** Current user can helper */\nfunction can(string $cap): bool {\n    return current_user_can($cap);\n}\n\n/** Sanitize decimal */\nfunction dec($val, int $dp = 4) {\n    return round((float) $val, $dp);\n}\n"
FILES['kyros-recipe-manager-Farhan.php'] = "<?php\n/**\n * Plugin Name:  Kyros Recipe Manager By Farhan\n * Plugin URI:   https://example.com\n * Description:  Internal recipe & ingredient management with live cost calculator, roles, approvals, PDF export, shortcode & block.\n * Version:      1.3.0\n * Author:       Farhan\n * Author URI:   https://example.com\n * Text Domain:  kyros-recipe-manager\n * Requires PHP: 7.4\n * Requires at least: 6.0\n * License: GPLv2 or later\n */\n\ndefined('ABSPATH') || exit;\n\ndefine('KRM_VERSION', '1.3.0');\ndefine('KRM_FILE', __FILE__);\ndefine('KRM_PATH', plugin_dir_path(__FILE__));\ndefine('KRM_URL',  plugin_dir_url(__FILE__));\ndefine('KRM_TEXT_DOMAIN', 'kyros-recipe-manager');\n\nrequire_once KRM_PATH . 'includes/helpers.php';\nrequire_once KRM_PATH . 'includes/class-roles.php';\nrequire_once KRM_PATH . 'includes/class-db.php';\nrequire_once KRM_PATH . 'includes/class-plugin.php';\nrequire_once KRM_PATH . 'includes/class-cpt-ingredient.php';\nrequire_once KRM_PATH . 'includes/class-cpt-recipe.php';\nrequire_once KRM_PATH . 'includes/class-admin.php';\nrequire_once KRM_PATH . 'includes/class-calculator.php';\nrequire_once KRM_PATH . 'includes/class-shortcode.php';\nrequire_once KRM_PATH . 'includes/class-export.php';\nrequire_once KRM_PATH . 'includes/class-notify.php';\nrequire_once KRM_PATH . 'includes/class-block.php';\n\nregister_activation_hook(__FILE__, function() {\n    \\Kyros\\RecipeManager\\Roles::add_roles();\n    \\Kyros\\RecipeManager\\Roles::add_caps();\n    \\Kyros\\RecipeManager\\DB::maybe_install();\n    // defaults\n    add_option('krm_currency', 'MYR');\n    add_option('krm_unit_system', 'metric');\n    add_option('krm_misc_pct', (int) 10);\n    add_option('krm_cost_color_thresholds', array('good' => 30, 'warn' => 40));\n    // Allergen master list\n    add_option('krm_allergens_master', array(\n        'gluten','crustaceans','eggs','fish','peanuts','soybeans','milk','tree_nuts',\n        'celery','mustard','sesame','sulphites','lupin','molluscs'\n    ));\n    flush_rewrite_rules();\n});\n\nregister_deactivation_hook(__FILE__, function() {\n    flush_rewrite_rules();\n});\n\nadd_action('plugins_loaded', function() {\n    load_plugin_textdomain('kyros-recipe-manager', false, dirname(plugin_basename(__FILE__)) . '/languages');\n    \\Kyros\\RecipeManager\\Plugin::init();\n});\n"
FILES['languages/kyros-recipe-manager.pot'] = ''
FILES['readme.txt'] = '=== Kyros Recipe Manager By Farhan ===\nContributors: kyros\nTags: recipe, cost, calculator, ingredient, pdf\nRequires at least: 6.0\nTested up to: 6.0\nRequires PHP: 7.4\nStable tag: 1.3.0\nLicense: GPLv2 or later\n\nInternal recipe & ingredient management with live cost calculator, roles, approvals, PDF export, shortcode & block.\n\n== Description ==\nKyros Kebab internal plugin for recipe & ingredient management.\n- Custom post types: Ingredient, Recipe\n- Live calculator (shortcode [recipe_calculator id="123"] and block)\n- Roles: krm_admin, krm_operation, krm_supervisor\n- Settings: currency, unit system, allergen master list, misc %\n- Print-friendly SOP export (browser print)\n- Malay translation ready\n\n== Installation ==\n1. Copy folder to wp-content/plugins/\n2. Activate.\n3. Assign roles to users.\n4. Configure Settings (Recipe Ops → Settings).\n5. Add Ingredients, then Recipes.\n6. Embed calculator via shortcode or block.\n\n== Changelog ==\n= 1.3.0 =\n* Initial V3 scaffold.\n'
FILES['templates/frontend-calculator.php'] = '<?php\n/** @var int $recipe_id */\nuse Kyros\\RecipeManager\\Calculator;\nuse Kyros\\RecipeManager\\DB;\n\ndefined(\'ABSPATH\') || exit;\n\n$recipe_id = isset($recipe_id) ? absint($recipe_id) : 0;\nif (!isset($recipe_id)) { $recipe_id = 0; }\n$rows = $recipe_id ? DB::items_for_recipe($recipe_id) : array();\n$misc_default = (int) \\Kyros\\RecipeManager\\opt(\'krm_misc_pct\', 10);\n?>\n<div class="krm-card krm-calculator">\n  <div class="krm-header">\n    <h2><?php _e(\'Cost Calculation\', KRM_TEXT_DOMAIN); ?></h2>\n    <?php if (current_user_can(\'edit_recipes\') && $recipe_id): ?>\n      <button class="button krm-save" id="krm-save-menu"><?php _e(\'Save Menu\', KRM_TEXT_DOMAIN); ?></button>\n    <?php endif; ?>\n  </div>\n\n  <table class="krm-table">\n    <thead>\n      <tr>\n        <th><?php _e(\'Ingredient\', KRM_TEXT_DOMAIN); ?></th>\n        <th><?php _e(\'Unit\', KRM_TEXT_DOMAIN); ?></th>\n        <th><?php _e(\'Cost/Unit (RM)\', KRM_TEXT_DOMAIN); ?></th>\n        <th><?php _e(\'Quantity\', KRM_TEXT_DOMAIN); ?></th>\n        <th class="krm-right"><?php _e(\'Total (RM)\', KRM_TEXT_DOMAIN); ?></th>\n        <th></th>\n      </tr>\n    </thead>\n    <tbody id="krm-rows">\n      <?php if (empty($rows)): ?>\n        <tr class="krm-row">\n          <td><input type="text" class="krm-ingredient" placeholder="Select…" /></td>\n          <td>\n            <select class="krm-unit">\n              <option>g</option><option>kg</option><option>ml</option><option>L</option><option>piece</option>\n            </select>\n          </td>\n          <td><input type="number" step="0.0001" class="krm-cost" value="0" /></td>\n          <td><input type="number" step="0.0001" class="krm-qty" value="0" /></td>\n          <td class="krm-right krm-subtotal">RM 0.00</td>\n          <td><button class="krm-del">🗑</button></td>\n        </tr>\n      <?php else: foreach ($rows as $r): ?>\n        <tr class="krm-row">\n          <td><input type="text" class="krm-ingredient" value="<?php echo esc_attr(get_the_title((int)$r[\'ingredient_post_id\'])); ?>" /></td>\n          <td><input type="text" class="krm-unit" value="<?php echo esc_attr($r[\'unit\']); ?>" /></td>\n          <td><input type="number" step="0.0001" class="krm-cost" value="<?php echo esc_attr($r[\'cost_snapshot\']); ?>" /></td>\n          <td><input type="number" step="0.0001" class="krm-qty" value="<?php echo esc_attr($r[\'quantity\']); ?>" /></td>\n          <td class="krm-right krm-subtotal"></td>\n          <td><button class="krm-del">🗑</button></td>\n        </tr>\n      <?php endforeach; endif; ?>\n    </tbody>\n  </table>\n\n  <p><button class="button button-primary krm-add">+ <?php _e(\'Add Ingredient\', KRM_TEXT_DOMAIN); ?></button></p>\n\n  <div class="krm-summary">\n    <div class="krm-box">\n      <div><?php _e(\'Total Cost\', KRM_TEXT_DOMAIN); ?></div>\n      <div class="krm-total">RM 0.00</div>\n    </div>\n    <div class="krm-box">\n      <label><?php _e(\'Misc (%)\', KRM_TEXT_DOMAIN); ?></label>\n      <input type="number" id="krm-misc" value="<?php echo esc_attr($misc_default); ?>" />\n      <div class="krm-misc-rm">RM 0.00</div>\n    </div>\n    <div class="krm-box">\n      <label><?php _e(\'Selling Price (RM)\', KRM_TEXT_DOMAIN); ?></label>\n      <input type="number" id="krm-sell" value="0" />\n      <div><?php _e(\'Cost %\', KRM_TEXT_DOMAIN); ?> <span id="krm-costpct" class="krm-badge">0.0%</span></div>\n    </div>\n  </div>\n\n  <div class="krm-total-final"><?php _e(\'Total with Misc\', KRM_TEXT_DOMAIN); ?> <strong id="krm-grand">RM 0.00</strong></div>\n  <?php if ($recipe_id): ?><input type="hidden" id="krm-recipe-id" value="<?php echo (int)$recipe_id; ?>" /><?php endif; ?>\n</div>\n'
FILES['templates/recipe-sop.php'] = "<?php\ndefined('ABSPATH') || exit;\n/* Placeholder SOP template; enhance as needed. */\nthe_post();\necho '<h1>' . esc_html(get_the_title()) . '</h1>';\necho '<div>' . wp_kses_post(get_the_excerpt()) . '</div>';\n"
FILES['tests/README.md'] = '# Tests\nPlaceholder for future PHPUnit tests.\n'
FILES['uninstall.php'] = '<?php\ndefined(\'WP_UNINSTALL_PLUGIN\') || exit;\n\nglobal $wpdb;\n$prefix = $wpdb->prefix;\n$table  = $prefix . \'krm_recipe_items\';\n$wpdb->query("DROP TABLE IF EXISTS $table");\n\n// Delete options\n$opts = array(\n  \'krm_currency\',\n  \'krm_unit_system\',\n  \'krm_misc_pct\',\n  \'krm_cost_color_thresholds\',\n  \'krm_allergens_master\',\n  \'krm_db_version\'\n);\nforeach ($opts as $o) { delete_option($o); }\n\n// Remove roles/caps\nrequire_once __DIR__ . \'/includes/class-roles.php\';\n\\Kyros\\RecipeManager\\Roles::remove_caps();\n\\Kyros\\RecipeManager\\Roles::remove_roles();\n'
ROOT.mkdir(parents=True, exist_ok=True)
for rel, data in FILES.items():
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(data)
print(f'Generated plugin at {ROOT}')
PY

command -v zip >/dev/null 2>&1 || { echo "❌ 'zip' command not found. Install it (apt-get install zip / brew install zip) and re-run."; exit 1; }

rm -f "$ZIP_PATH"

(
  cd "$SCRIPT_DIR" && zip -rq "$ZIP_PATH" "$PLUGIN_SLUG" -x "*/.DS_Store"
)
(
  cd "$SCRIPT_DIR" && zip -qj "$ZIP_PATH" "$SCRIPT_PATH"
)

echo "✅ Packaged: $ZIP_PATH"
echo "Next: WordPress Admin → Plugins → Add New → Upload Plugin → select ${PLUGIN_SLUG}.zip → Install → Activate."
