       // my little shopify shop
if (typeof(console) == 'undefined') {
    var console = {
        log: function() {},
        info: function() {},
        warn: function() {},
        error: function() {},
        time: function() {}
    }
}
else if (typeof(console.log) == 'undefined') {
    console.log = function() {};
}

$(document).ready(function() {
   $("#delete", "#destroy_related_form").click(function(){
      $("#destroy_related_form").submit();
   });
});