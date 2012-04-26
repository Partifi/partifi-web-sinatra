(function ($) {
  //Partifi functions
  $.partifi = $.partifi || {};
  $.extend($.partifi, {
  	init: function() {
  		var $this = this;
  		  		
  		this.opts = {
  			user: null,
  			event: null
  		};
  		
		$('#request').submit(function() {		
			$this.searchTrack($('#request input[name=query]').val());
			
			return false;
		});
		
		$(".requestbutton").click(function() {			
			
			$this.hidePlaylist();
			$this.showRequest();
		
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
		 	console.log(item);
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
		
		console.log(this.opts.event);
		
		this.hideEvents();
		
		this.loadPlaylist();
	},
	loadPlaylist: function() {
		var $this = this;
				
		var event = this.opts.event;
		
		$.getJSON('/playlist/' + event.id, function(data) {
			$this.showPlaylist(data.Playlist);
		});
	},	
	showPlaylist: function(songs) {
		var $this = this;
	
		var ul = $("<ul></ul>");
		$(songs).each(function(index, item) {
			if (index == 0) {
				$this.showCurrent(item);
				return;
			}
			
			var name = item.artist + " - " + item.name;
			
			var li = $("<li data-index='"+ index + "'>" + name + " <span data-status='love'>Love</span> <span data-status='hate'>Hate</span></li>");
			
			li.find('span').click(function() {
				$this.vote(item, $(this).attr('data-status'));
			});
			
			ul.append(li);
		});
		
		$("#playlist .container").html(ul);
		$("#playlist").show();

	},	
	showCurrent: function(song) {
		var $this = this;

		
		$('#current-song h2').text(song.artist + " - " + song.name);
		$('#current-song-image').html("<img src='"+song.img+"' />");

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
	showRequest: function() {
		$('#request').show();
	},
	hideRequest: function() {
		$('#request').hide();
	},
	searchTrack: function(query) {
		var $this = this;
		
		$.getJSON("/search/" + escape(query), function(data) {
			$this.searchTrackResult(data);
		});
	},
	searchTrackResult: function(data) {
	
		if (data.tracks.length == 0) {
			$('#request .error').show();
			return;
		}
		
		$('#request .error').hide();		
	
		this.sendTrack(data.tracks[0]);
	},
	sendTrack: function(track) {	
		var $this = this;
		var event = this.opts.event;
		var user = this.opts.user;
		
		this.hideRequest();
		
		var artists = [];
				
		$(track.artists).each(function(index, item) {
			artists.push(item.name);
		});
		
		var data = {
			user_id: user.id,
			uri: track.href,
			name: track.name,
			artist: artists.join(", ")
		}
		
		$.post('/playlist/' + event.id, data, function(data) {
			$this.loadPlaylist();
		});
	}
  });
  
}(jQuery));
