<?php
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
        <table class="form-table">
            <tr><th><?php _e('Measurement Family', KRM_TEXT_DOMAIN); ?></th>
                <td>
                    <select name="krm_measurement_family">
                        <option value="mass" <?php selected($family, 'mass'); ?>>mass (g/kg)</option>
                        <option value="volume" <?php selected($family, 'volume'); ?>>volume (ml/L)</option>
                        <option value="piece" <?php selected($family, 'piece'); ?>>piece</option>
                    </select>
                    <p class="description"><?php _e('Choose how this ingredient is measured.', KRM_TEXT_DOMAIN); ?></p>
                </td></tr>
            <tr><th><?php _e('Base Unit', KRM_TEXT_DOMAIN); ?></th>
                <td>
                    <input type="text" name="krm_unit_base" value="<?php echo esc_attr($unit_base); ?>" />
                    <span class="description"><?php _e('kg, L, piece …', KRM_TEXT_DOMAIN); ?></span>
                </td></tr>
            <tr><th><?php _e('Base Weight/Volume', KRM_TEXT_DOMAIN); ?></th>
                <td><input type="number" step="0.0001" name="krm_weight_base" value="<?php echo esc_attr($weight_base); ?>" /></td></tr>
            <tr><th><?php _e('Price per Base Unit (RM)', KRM_TEXT_DOMAIN); ?></th>
                <td><input type="number" step="0.0001" name="krm_price_per_base" value="<?php echo esc_attr($price_per_base); ?>" /></td></tr>
            <tr><th><?php _e('Density (g/ml, optional)', KRM_TEXT_DOMAIN); ?></th>
                <td><input type="number" step="0.0001" name="krm_density" value="<?php echo esc_attr($density); ?>" /></td></tr>
            <tr><th><?php _e('Supplier', KRM_TEXT_DOMAIN); ?></th>
                <td><input type="text" name="krm_supplier_name" value="<?php echo esc_attr($supplier_name); ?>" />
                <input type="text" name="krm_supplier_contact" value="<?php echo esc_attr($supplier_contact); ?>" placeholder="phone/email" /></td></tr>
            <tr><th><?php _e('Allergens', KRM_TEXT_DOMAIN); ?></th>
                <td>
                    <?php foreach ($allergens_master as $a): ?>
                      <label style="display:inline-block;margin-right:10px;"><input type="checkbox" name="krm_allergens[]" value="<?php echo esc_attr($a); ?>" <?php checked(in_array($a, $allergens, true)); ?> /> <?php echo esc_html($a); ?></label>
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
            echo esc_html("{$w} {$u} @ RM {$p}");
        } elseif ('krm_supplier' === $col) {
            echo esc_html(get_post_meta($post_id, 'krm_supplier_name', true));
        } elseif ('krm_allergens' === $col) {
            echo esc_html(implode(', ', (array) get_post_meta($post_id, 'krm_allergens', true)));
        } elseif ('krm_actions' === $col) {
            $edit = get_edit_post_link($post_id);
            if ($edit) {
                echo '<a class="button button-small" href="' . esc_url($edit) . '">' . esc_html__('Edit', KRM_TEXT_DOMAIN) . '</a>';
            }
        }
    }
}
