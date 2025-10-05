(function($){
  $('#krm-add-dir').on('click', function(){
    var i = $('#krm-dirs-body tr').length;
    var row = $('<tr>\
      <td><input type="number" name="krm_dirs['+i+'][step_no]" value="'+(i+1)+'" /></td>\
      <td><textarea name="krm_dirs['+i+'][instruction]" rows="2" style="width:100%"></textarea></td>\
    </tr>');
    $('#krm-dirs-body').append(row);
  });
})(jQuery);
