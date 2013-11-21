$(window).ready(function() {

  function update_status(stat) {
    $('#light').removeClass('open');
    $('#light').removeClass('closed');
    $('#light').removeClass('alarm');
    $('#light').addClass(stat);

    switch (stat) {
      case 'open': $('#light').text('Door Open'); break;
      case 'closed': $('#light').text('Door Closed'); break;
      case 'alarm': $('#light').text('Door Alarm'); break;
    }
  }

  var fridge = $('#light').data('fridge');

  update_status($('#light').data('status'));

  var client = new Faye.Client('/faye');
  client.subscribe('/fridge/' + fridge + '/door', function(data) {
    update_status(data);
  });

});
