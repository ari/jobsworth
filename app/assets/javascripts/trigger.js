jQuery(document).ready(function () {
  jQuery("form.edit_trigger img.delete_action").live('click', function () {
    jQuery(this).parents("div.action").remove();
  });

  jQuery("#add_action").change(function () {
    var select = jQuery(this).val();
    var block = jQuery("#action_factory_" + select);
    jQuery("div.actions").append(block.html());
  });
});