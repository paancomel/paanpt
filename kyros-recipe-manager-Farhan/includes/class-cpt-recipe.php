<?php
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
        <table class="form-table">
          <tr><th><?php _e('Servings', KRM_TEXT_DOMAIN); ?></th><td><input type="number" name="krm_servings" value="<?php echo esc_attr($servings); ?>" /></td></tr>
          <tr><th><?php _e('Yield Unit', KRM_TEXT_DOMAIN); ?></th><td><input type="text" name="krm_yield_unit" value="<?php echo esc_attr($yield_unit); ?>" /></td></tr>
          <tr><th><?php _e('Wastage %', KRM_TEXT_DOMAIN); ?></th><td><input type="number" step="0.01" name="krm_wastage_pct" value="<?php echo esc_attr($wastage); ?>" /></td></tr>
          <tr><th><?php _e('Prep Time (min)', KRM_TEXT_DOMAIN); ?></th><td><input type="number" name="krm_prep_time" value="<?php echo esc_attr($prep); ?>" /></td></tr>
          <tr><th><?php _e('Status', KRM_TEXT_DOMAIN); ?></th>
          <td>
            <select name="krm_status">
              <option value="draft" <?php selected($status, 'draft'); ?>>Draft</option>
              <option value="pending" <?php selected($status, 'pending'); ?>>Pending Approval</option>
              <option value="use" <?php selected($status, 'use'); ?>>Use</option>
              <option value="not_used" <?php selected($status, 'not_used'); ?>>Not used</option>
              <option value="stop" <?php selected($status, 'stop'); ?>>Stop production</option>
            </select>
            <a class="button" href="<?php echo esc_url(get_permalink($post->ID)); ?>" target="_blank"><?php _e('View SOP/Calculator', KRM_TEXT_DOMAIN); ?></a>
          </td></tr>
        </table>
        <?php
    }

    public static function box_dirs($post) {
        $dirs = (array) get_post_meta($post->ID, 'krm_directions', true);
        echo '<p class="description">' . esc_html__('Add cooking directions. One per row.', KRM_TEXT_DOMAIN) . '</p>';
        echo '<table class="widefat fixed"><thead><tr><th>#</th><th>' . esc_html__('Instruction', KRM_TEXT_DOMAIN) . '</th></tr></thead><tbody id="krm-dirs-body">';
        if (empty($dirs)) {
            $dirs = array(array('step_no' => 1, 'instruction' => ''));
        }
        foreach ($dirs as $i => $row) {
            $n = intval($row['step_no'] ?? $i + 1);
            $t = esc_textarea($row['instruction'] ?? '');
            echo '<tr><td><input type="number" name="krm_dirs[' . $i . '][step_no]" value="' . $n . '" /></td><td><textarea name="krm_dirs[' . $i . '][instruction]" rows="2" style="width:100%">' . $t . '</textarea></td></tr>';
        }
        echo '</tbody></table><p><button type="button" class="button" id="krm-add-dir">+ ' . esc_html__('Add Step', KRM_TEXT_DOMAIN) . '</button></p>';
    }

    public static function box_ing($post) {
        echo '<p class="description">' . esc_html__('Manage ingredient rows in the front-end calculator or here (MVP keeps it in front-end).', KRM_TEXT_DOMAIN) . '</p>';
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
                echo '<a class="button button-small" href="' . esc_url($edit) . '">' . esc_html__('Edit', KRM_TEXT_DOMAIN) . '</a>';
            }
        }
    }
}
