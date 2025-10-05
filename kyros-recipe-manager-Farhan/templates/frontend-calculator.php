<?php
/** @var int $recipe_id */
use Kyros\RecipeManager\Calculator;
use Kyros\RecipeManager\DB;

defined('ABSPATH') || exit;

$recipe_id = isset($recipe_id) ? absint($recipe_id) : 0;
if (!isset($recipe_id)) { $recipe_id = 0; }
$rows = $recipe_id ? DB::items_for_recipe($recipe_id) : array();
$misc_default = (int) \Kyros\RecipeManager\opt('krm_misc_pct', 10);
?>
<div class="krm-card krm-calculator">
  <div class="krm-header">
    <h2><?php _e('Cost Calculation', KRM_TEXT_DOMAIN); ?></h2>
    <?php if (current_user_can('edit_recipes') && $recipe_id): ?>
      <button class="button krm-save" id="krm-save-menu"><?php _e('Save Menu', KRM_TEXT_DOMAIN); ?></button>
    <?php endif; ?>
  </div>

  <table class="krm-table">
    <thead>
      <tr>
        <th><?php _e('Ingredient', KRM_TEXT_DOMAIN); ?></th>
        <th><?php _e('Unit', KRM_TEXT_DOMAIN); ?></th>
        <th><?php _e('Cost/Unit (RM)', KRM_TEXT_DOMAIN); ?></th>
        <th><?php _e('Quantity', KRM_TEXT_DOMAIN); ?></th>
        <th class="krm-right"><?php _e('Total (RM)', KRM_TEXT_DOMAIN); ?></th>
        <th></th>
      </tr>
    </thead>
    <tbody id="krm-rows">
      <?php if (empty($rows)): ?>
        <tr class="krm-row">
          <td><input type="text" class="krm-ingredient" placeholder="Select…" /></td>
          <td>
            <select class="krm-unit">
              <option>g</option><option>kg</option><option>ml</option><option>L</option><option>piece</option>
            </select>
          </td>
          <td><input type="number" step="0.0001" class="krm-cost" value="0" /></td>
          <td><input type="number" step="0.0001" class="krm-qty" value="0" /></td>
          <td class="krm-right krm-subtotal">RM 0.00</td>
          <td><button class="krm-del">🗑</button></td>
        </tr>
      <?php else: foreach ($rows as $r): ?>
        <tr class="krm-row">
          <td><input type="text" class="krm-ingredient" value="<?php echo esc_attr(get_the_title((int)$r['ingredient_post_id'])); ?>" /></td>
          <td><input type="text" class="krm-unit" value="<?php echo esc_attr($r['unit']); ?>" /></td>
          <td><input type="number" step="0.0001" class="krm-cost" value="<?php echo esc_attr($r['cost_snapshot']); ?>" /></td>
          <td><input type="number" step="0.0001" class="krm-qty" value="<?php echo esc_attr($r['quantity']); ?>" /></td>
          <td class="krm-right krm-subtotal"></td>
          <td><button class="krm-del">🗑</button></td>
        </tr>
      <?php endforeach; endif; ?>
    </tbody>
  </table>

  <p><button class="button button-primary krm-add">+ <?php _e('Add Ingredient', KRM_TEXT_DOMAIN); ?></button></p>

  <div class="krm-summary">
    <div class="krm-box">
      <div><?php _e('Total Cost', KRM_TEXT_DOMAIN); ?></div>
      <div class="krm-total">RM 0.00</div>
    </div>
    <div class="krm-box">
      <label><?php _e('Misc (%)', KRM_TEXT_DOMAIN); ?></label>
      <input type="number" id="krm-misc" value="<?php echo esc_attr($misc_default); ?>" />
      <div class="krm-misc-rm">RM 0.00</div>
    </div>
    <div class="krm-box">
      <label><?php _e('Selling Price (RM)', KRM_TEXT_DOMAIN); ?></label>
      <input type="number" id="krm-sell" value="0" />
      <div><?php _e('Cost %', KRM_TEXT_DOMAIN); ?> <span id="krm-costpct" class="krm-badge">0.0%</span></div>
    </div>
  </div>

  <div class="krm-total-final"><?php _e('Total with Misc', KRM_TEXT_DOMAIN); ?> <strong id="krm-grand">RM 0.00</strong></div>
  <?php if ($recipe_id): ?><input type="hidden" id="krm-recipe-id" value="<?php echo (int)$recipe_id; ?>" /><?php endif; ?>
</div>
