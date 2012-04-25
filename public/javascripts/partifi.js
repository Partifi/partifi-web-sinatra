(function ($) {
  //Partifi functions
  $.partifi = $.partifi || {};
  $.extend($.partifi, {
  	init: function() {
  		var $this = this;
  	
  		this.opts = {
  			user: null,
  			event: null
  		}
  		
		$('#request').submit(function(event) {
			event.stopPropagation();
		
			$this.searchTrack($('#request input[name=query]').val());
			
			return false;
		});
  	},
  	registerUser: function(user) {
  	  	var $this = this;
  	  	
		this.opts.user = user;
		
		console.log(user);		
		
		$.fb.listEvents(function(data) {
			$this.showEvents(data);
		});
  	},
	showEvents:function(events) {
		var $this = this;
	
		var ul = $("<ul></ul>");
		$(events).each(function(index, item) {
		  var name = item.name;
		    
		  var li = $("<li data-index='"+ index + "'>" + name + "</li>");
		  
		  li.click(function() {
		  	$this.registerEvent(item);
		  });
		      
		  ul.append(li);
		});
		
		$("#eventlist").html(ul).show();	
	},
	hideEvents: function() {
		$("#eventlist").hide();
	},
	registerEvent: function(event) {
		this.opts.event = event;
		
		this.hideEvents();
		
		this.loadPlaylist();
	},
	loadPlaylist: function() {
		var $this = this;
		
		var event = this.opts.event.id;
		
		$.getJSON('/playlist/' + event.id, function(data) {
			$this.showPlaylist(data.Playlist);
		});
	},	
	showPlaylist: function(songs) {
		var $this = this;
	
		var ul = $("<ul></ul>");
		$(songs).each(function(index, item) {
			console.log(item);
			
			var name = item.artist + " - " + item.name;
			
			var li = $("<li data-index='"+ index + "'>" + name + "</li> <span data-status='love'>Love</span> <span data-status='hate'>Hate</span>");
			
			li.find('span').click(function() {
				$this.vote(item, $(this).attr('data-status'));
			});
			
			ul.append(li);
		});
		
		$("#playlist").html(ul).show();
	},	
	hidePlaylist: function() {
		$('#playlist').hide();
	},
	vote: function(song, status) {
		var $this = this;
		
		var data = {
			user_id: this.opts.user.id,
			song_id: song.id,
			status: status
		}
		
		$.post('/vote/' + song.id, data, function(response) {
			$this.loadPlaylist();
		});
	},
	searchTrack: function(query) {
		var $this = this;
		
				
	}
  });
  
  $.partifi.init();
}(jQuery));

