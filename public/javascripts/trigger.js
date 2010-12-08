jQuery(document).ready(function(){
    jQuery("form.edit_trigger img.delete_action").click(function(){
        jQuery(this).parents("div.action").remove();
    });
});