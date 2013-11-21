$(window).ready(function() {

  var temp = new TimeSeries();

  var tempchart = new SmoothieChart({
    millisPerPixel:150,
    grid: {
      fillStyle: 'transparent',
      millisPerLine: 4000,
      verticalSections: 7,
      borderVisible: false,
      strokeStyle: '#c9c9c9'
    },
    labels: {
      fillStyle: '#999'
    }
  });
  tempchart.addTimeSeries(temp, {
    strokeStyle: '#578bff',
    lineWidth: 2 
  });
  tempchart.streamTo(document.getElementById("tempchart"), 3000);

  var pressure = new TimeSeries();

  var pressurechart = new SmoothieChart({
    millisPerPixel:150,
    minValue: 800,
    maxValue: 1100,
    grid: {
      fillStyle: 'transparent',
      millisPerLine: 4000,
      verticalSections: 7,
      borderVisible: false,
      strokeStyle: '#c9c9c9'
    },
    labels: {
      fillStyle: '#999'
    }
  });
  pressurechart.addTimeSeries(pressure, {
    strokeStyle: '#578bff',
    lineWidth: 2 
  });
  pressurechart.streamTo(document.getElementById("pressurechart"), 3000);

  $.getJSON(document.location.href + '.json', function(data) {
    $.each(data, function() {
      temp.append(this.now, this.temperature);
      pressure.append(this.now, this.pressure);
    });
  });

  var fridge = $('#tempchart').data('fridge');

  var client = new Faye.Client('/faye');
  client.subscribe('/fridge/' + fridge + '/point', function(data) {
    temp.append(data.now, data.temperature);
    pressure.append(data.now, data.pressure);
  });

});
