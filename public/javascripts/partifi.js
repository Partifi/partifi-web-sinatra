(function ($) {
  //Partifi functions
  $.partifi = $.partifi || {};
  $.extend($.partifi, {
  	init: function() {
  		var $this = this;
  		  		
  		this.opts = {
  			user: null,
  			event: null,
  			song: null
  		};
  		
		$('#request').submit(function() {		
			$this.searchTrack($('#request input[name=query]').val());
			
			return false;
		});
		
		$("#requestbutton").click(function() {			
			
			$this.hidePlaylist();
			$this.showRequest();
		
			return false;
		});
		
		$('#current-song-hate').click(function() {
			console.log($this.opts.song);
					
			$this.vote($this.opts.song, "hate");
			
			return false;
		});
  	},
  	registerUser: function(user) {
  	  	var $this = this;
  	  	
		this.opts.user = user;
				
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
		
		$("#events").html(ul).show();	
	},
	hideEvents: function() {
		$("#events").hide();
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
		
		$.getJSON(this.playListUrlWithTimestamp(event.id), function(data) {
		  $this.showCurrent(data.Playlist)
			$this.showUpcomingPlaylist(data.Playlist);
		});
	},	
	showUpcomingPlaylist: function(songs) {
		var $this = this;
		
		$("#top10 tbody").empty();
		
		$('#request').show();
		
		$(songs).each(function(index, song) {
		  // skip the current song for this list
		  if ($this.isCurrentSong(song)) { return };
			
			var name = song.artist + " - " + song.name;
			
			var li = $("<tr><td width='140'>" + song.name + "</td><td width='140'>" + song.artist + "</td><td><span data-status='love'><img src='/img/heart.png' /></span></td><td><span data-status='hate'><img src='/img/heart-dislike.png' /></span></td>");
			
			li.find('span').click(function() {
				$this.vote(song, $(this).attr('data-status'));
			});
			
			$("#top10 tbody").append(li);			
		});
		
		$("#top10").show();

	},
	showCurrent: function(songs) {
		var $this = this;
		var currentSong = null;
		
		$(songs).each(function(i, song) {
		  if ($this.isCurrentSong(song)) { currentSong = song };
		});
		
		this.opts.song = currentSong;

		if (currentSong) {
  		$('#current-song').show();
  		$('#current-song h2').text(currentSong.artist + " - " + currentSong.name);
		};
	},
	isCurrentSong: function(song) {
	  return !!song.currently_playing;
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
//		$('#request').show();
	},
	hideRequest: function() {
//		$('#request').hide();
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
		
		$.post(this.playListUrlWithTimestamp(event.id), data, function(data) {
			$this.loadPlaylist();
		});
	},
	playListUrlWithTimestamp: function(event_id) {
	  var timestamp = new Date().getTime();
    return '/playlist/'+ event_id + '?r= ' + timestamp
	}
  });
  
}(jQuery));
