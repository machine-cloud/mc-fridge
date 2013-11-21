$(window).ready(function() {

  var fridge = $('#update').data('fridge');

  $('#update').on('click', function() {
    $.get('/fridge/' + fridge + '/update');
  });

});
