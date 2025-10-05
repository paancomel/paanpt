(function($){
  function fmt(n){ return 'RM ' + Number(n||0).toFixed(2); }
  function recalc(){
    var total = 0;
    $('#krm-rows tr.krm-row').each(function(){
      var qty = parseFloat($('.krm-qty', this).val())||0;
      var cost = parseFloat($('.krm-cost', this).val())||0;
      var sub = qty * cost; // waste handled in future per-row
      total += sub;
      $('.krm-subtotal', this).text(fmt(sub));
    });
    $('.krm-total').text(fmt(total));
    var miscPct = parseFloat($('#krm-misc').val())||0;
    var miscRM = total * (miscPct/100);
    $('.krm-misc-rm').text(fmt(miscRM));
    var grand = total + miscRM;
    $('#krm-grand').text(fmt(grand));
    var sell = parseFloat($('#krm-sell').val())||0;
    var pct = sell>0 ? ((total/sell)*100) : 0;
    var badge = $('#krm-costpct').text(pct.toFixed(1)+'%');
    badge.removeClass('good warn bad');
    if (pct<=30) badge.addClass('good'); else if (pct<=40) badge.addClass('warn'); else badge.addClass('bad');
  }
  $(document).on('input change','#krm-rows input, #krm-misc, #krm-sell', recalc);
  $(document).on('click','.krm-add', function(){
    var row = $('<tr class="krm-row">\
      <td><input type="text" class="krm-ingredient" placeholder="Select…" /></td>\
      <td><select class="krm-unit"><option>g</option><option>kg</option><option>ml</option><option>L</option><option>piece</option></select></td>\
      <td><input type="number" step="0.0001" class="krm-cost" value="0" /></td>\
      <td><input type="number" step="0.0001" class="krm-qty" value="0" /></td>\
      <td class="krm-right krm-subtotal">RM 0.00</td>\
      <td><button class="krm-del">🗑</button></td>\
    </tr>');
    $('#krm-rows').append(row);
    recalc();
  });
  $(document).on('click','.krm-del', function(e){ e.preventDefault(); $(this).closest('tr').remove(); recalc(); });

  $('#krm-save-menu').on('click', function(e){
    e.preventDefault();
    var recipeId = parseInt($('#krm-recipe-id').val()||0,10);
    if (!recipeId){ alert('No recipe ID.'); return; }
    var rows = [];
    $('#krm-rows tr.krm-row').each(function(){
      rows.push({
        ingredient_id: 0, // MVP, manual typed name
        unit: $('.krm-unit', this).val(),
        unit_cost: parseFloat($('.krm-cost', this).val())||0,
        quantity: parseFloat($('.krm-qty', this).val())||0,
        waste_pct: 0
      });
    });
    $.post(KRM.ajax, {action:'krm_save_menu', nonce:KRM.nonce, recipe_id:recipeId, rows:rows}, function(resp){
      if (resp && resp.success){ alert('Saved'); } else { alert('Save failed'); }
    });
  });

  $(function(){ recalc(); });
})(jQuery);
