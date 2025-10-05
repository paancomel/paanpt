(function(wp){
  const el = wp.element.createElement;
  const registerBlockType = wp.blocks.registerBlockType;

  registerBlockType('krm/recipe-calculator', {
    title: 'Recipe Calculator',
    icon: 'clipboard',
    category: 'widgets',
    attributes: { recipeId: { type: 'number', default: 0 } },
    edit: function(props){
      return el('div', {className:'krm-block'},
        el('label', null, 'Recipe ID: ',
          el('input', {type:'number', value: props.attributes.recipeId,
            onChange: (e)=>props.setAttributes({recipeId: parseInt(e.target.value||0,10)})})
        ),
        el('p', null, 'This block renders the front-end calculator for the selected recipe.')
      );
    },
    save: function(){ return null; } // dynamic
  });
})(window.wp);
