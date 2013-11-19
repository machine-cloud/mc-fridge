$(window).ready(function() {

  var temp = new TimeSeries();

  // setInterval(function() {
  //   random.append(new Date().getTime(), Math.random() * 10000);
  // }, 3000);

  var chart = new SmoothieChart({ millisPerPixel:150, minValue:0, maxValue:35 });
  chart.addTimeSeries(temp, { strokeStyle: 'rgba(0, 255, 0, 1)', fillStyle: 'rgba(0, 255, 0, 0.2)', lineWidth: 4 });
  chart.streamTo(document.getElementById("chart"), 3000);

  $.getJSON(document.location.href + '.json', function(data) {
    $.each(data, function() {
      temp.append(this.now, this.temperature)
    });
  });

  var fridge = $('#chart').data('fridge');

  var client = new Faye.Client('/faye');
  client.subscribe('/fridge/' + fridge + '/point', function(data) {
    temp.append(data.now, data.temperature);
  });

});
