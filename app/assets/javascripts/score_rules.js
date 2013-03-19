/****
* Code for the score rule widget
****/
function showLoadingAnimationFor(srContainer) {
  animation = '<%= image_tag("spinner.gif") %>'
  srContainer.append(animation);
}

function wireFormFor(srContainer) {

  var forms = srContainer.find(".score_rule_form");

  jQuery.each(forms, function(index, form) {
    jQuery(form).ajaxForm({
      beforeSubmit: function() {
        srContainer.empty();
        showLoadingAnimationFor(srContainer);
      },
      success: function(responseText, statusText, xhr, $form) {
        srContainer.empty();
        srContainer.append(responseText);
        //In case we got a validation error with the form
        wireFormFor(srContainer);
      } 
    });
  });
}

function wireActionLinksFor(srContainer) {
  var actionButtons = [];
  actionButtons.push({ element: srContainer.find(".new-score-rule"), action: 'GET' });
  actionButtons.push({ element: srContainer.find(".edit-score-rule"), action: 'GET' });
  actionButtons.push({ element: srContainer.find(".delete-score-rule"), action: 'DELETE' });

  jQuery.each(actionButtons, function(index, actionButton) {
    actionButton.element.live('click', function() {
      srContainer.empty();
      showLoadingAnimationFor(srContainer);

      var uri = jQuery(this).attr('href');

      jQuery.ajax({
        url: uri,
        type: actionButton.action,
        success: function(data) {
          srContainer.empty();
          srContainer.append(data);
          wireFormFor(srContainer);
        }
      });

      return false;
    });
  });
}

function getUriForScoreRules(scoreRulesContainer) {

  var match = scoreRulesContainer.attr('class').match(/for-(\w+)-(\d+)/);

  if(match != null) { 
    var containerName = match[1];
    var containerId   = match[2];
    return "/" + containerName + "/" + containerId + "/" + "score_rules";
  }

  return false; 
}

function getSrContainers() {
  var containers = [];

  jQuery(".score-rules-container").each(function() {
    var srContainer = jQuery(this); 
    var uri         = getUriForScoreRules(srContainer);

    if(uri) {
      containers.push({ uri: uri, element: srContainer });
    }

  });

  return containers;
}

function populateSrContainers(srContainers) {
  jQuery.each(srContainers, function(index, srContainer) {
    showLoadingAnimationFor(srContainer.element);

    jQuery.ajax({
      url: srContainer.uri,
      type: 'GET',
      success: function(data){
        srContainer.element.empty();
        srContainer.element.append(data);
        wireActionLinksFor(srContainer.element);
       }
    });
  });
}


jQuery(document).ready(function() {
  //sr --> Score Rule
  var srContainers = getSrContainers();
  populateSrContainers(srContainers);
});
