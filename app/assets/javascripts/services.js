// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var jobsworth = jobsworth || {}
jobsworth.services = jobsworth.services || {}

jobsworth.services.ServiceEditor = (function($) {
  function ServiceEditor(options) {
    this.options = options;
    this.bindEvents();   
  }

  ServiceEditor.prototype.selectCustomerAutoCompleteCallback = function(e, ui) {
    showProgress();
    $.post("/service_level_agreements", {service_level_agreement:{customer_id:ui.item.id, service_id:this.options.service_id}}, function(data) {
      hideProgress();
      if(data.success) {
        $(".service-level-agreements").append(data.html);
      } else {
        alert(data.message);
      }
      $("#service-edit-autocomplete-for-customer").val('');
    }) 
  }

  ServiceEditor.prototype.selectServiceAutoCompleteCallback = function(e, ui) {
    showProgress();
    $.post("/service_level_agreements", {service_level_agreement:{service_id:ui.item.id, customer_id:this.options.customer_id}}, function(data) {
      hideProgress();
      if(data.success) {
        $(".service-level-agreements").append(data.html);
      } else {
        alert(data.message);
      }
      $("#service-edit-autocomplete-for-service").val('');
    })
  }

  ServiceEditor.prototype.updateBillable = function(sla_id, billable, $sla_node) {
    $(".badge-success", $sla_node).addClass("hide");
    $("img.ajax", $sla_node).removeClass("hide");
    $.ajax({
      type: "PUT",
      url: "/service_level_agreements/" + sla_id,
      data: {service_level_agreement:{billable:billable}},
      success: function(data) {
        $("img.ajax", $sla_node).addClass("hide");
        if(data.success) {
          $(".badge-success", $sla_node).removeClass("hide");
        } else {
          alert(data.message);
        }
      }
    });
  }

  ServiceEditor.prototype.bindEvents = function() {
    var self = this;

    // set up autocomplete for customer
    $("#service-edit-autocomplete-for-customer").autocomplete({
      source: "/customers/auto_complete_for_customer_name",
      delay: 800,
      minlength: 3,
      search: showProgress,
      open: hideProgress,
      select: function(e, ui) { self.selectCustomerAutoCompleteCallback(e, ui); }
    }).bind("ajax:complete", hideProgress);

    // set up autocomplete for service
    $("#service-edit-autocomplete-for-service").autocomplete({
      source: "/services/auto_complete_for_service_name",
      delay: 800,
      minlength: 3,
      search: showProgress,
      open: hideProgress,
      select: function(e, ui) { self.selectServiceAutoCompleteCallback(e, ui); }
    }).bind("ajax:complete", hideProgress);

    // update billable
    $(".service_level_agreement input").live("change", function() {
      var sla_id = $(this).parents(".service_level_agreement").data("id");
      var billable = this.checked;
      self.updateBillable(sla_id, billable, $(this).parents(".service_level_agreement"));
    })

    // delete item
    $(".service_level_agreement a.delete").live("click", function() {
      var $sla_node = $(this).parents(".service_level_agreement")
      var sla_id = $sla_node.data("id");

      $(".badge-success", $sla_node).addClass("hide");
      $("img.ajax", $sla_node).removeClass("hide");
      $.ajax({
        type: "DELETE",
        url: "/service_level_agreements/" + sla_id,
        success: function(data) {
        $("img.ajax", $sla_node).addClass("hide");
          if(data.success) {
            $sla_node.remove();
          } else {
            alert(data.message);
          }
        }
      });
    })
  }

  return ServiceEditor;
})(jQuery)
