(function ($) {
  window.fbAsyncInit = function() {
    $.fb.init();
  };

  $(function () {  
    // 1 get user to select event OR get it from localstorage
    // 2 get current playing song and list from matched event
    // 3 show current playing song, bash button, list, search etc.
  });

  //facebook functions
  $.fb = $.fb || {};
  $.extend($.fb, {
    init: function () {
      FB.init({
        appId: '342859172429389',
        cookie: true,
        status: true,
        xfbml: true
      });

      this.opts = {
        name: '',
        id: '',
      }
      //bind login button
      $(".loginbutton").bind('click', function () {
        FB.login(function (response) {
          if (response.session) {
            $.fb.loggedIn();
          }
        }, {scope: 'user_events'});
        return false;
      });

      //check current status
      this.loggedIn();
    },
    loggedIn: function () {
      FB.getLoginStatus(function (response) {
        if (response.status == "connected") {
          // logged in and connected user, someone you know
          $(".loginbutton").hide();
          
          //show user icon and name
          FB.api('/me', function(response) {
            $.fb.opts.id = response.id;
            $.fb.opts.name = response.name;
            
            $.partifi.registerUser(response);
            
            $(".topbar").append("<span class='user'>" + response.name + "<img src='https://graph.facebook.com/" + response.id + "/picture'></span>");
          });

        } else {
          $(".loginbutton").show();
        }
      });
    },
    listEvents: function(completed) {
		FB.api('/me/events', function(response) {
			completed(response.data);
		});    
    }
  });
}(jQuery));

