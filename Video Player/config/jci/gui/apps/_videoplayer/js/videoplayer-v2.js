/*
 *
 * v2.0 Initial Version
 * v2.1 Included more video types
 * v2.2 Enabled the fullscreen Option
 * v2.3 Included the status bar and adjusts to play in a window
 * v2.4 Included a shuffle option
 *      fixed the problem of pressing the next button rapidly
 *      The list updates automaticaly at start
 * v2.5 It can now logs the steps (have to enable it on the videoplayer-v2.js & videoplayer.sh files)
 *		closes the app if is not the current (first attempt)
 *		fixes the issue of pressing mutiple times the search video button
 *		fixes the application not showing the controls again when a video play fails
 *		fixes playing the same video when shuffle is active
 *		starts using a swap file on start of the app if not running (still have to create the swap with the AIO)
 * v2.6 Change gst-launch for gplay, incorporing pause, resume, rw, ff
 *		Direct send of commands to sh (Better control)
 *		Close of WebSocket as it should be (saves memory)
 *		Change of port 55555 to 9998 in order to avoid problems with some cmu processes
 *		Bugfix for files with more than one consecutive white space
 *		Most of the times it stops the video when you put reverse with no problems
 * v2.7 Include pause when touching the video in the center, rewind when touching the left side and Fast Forward when touching the right side. (15% of the screen each)
 *		Correct problem when stopping a paused video (the icon shows an incorrect image at the beginning of the next video)
* v2.8 Multicontroller support - Tilt up/down = Scroll video list
*		Press command knob - Play/pause
*		Tilt Right - Next
*		Tilt left - Stop
*		Rotate command knob CCW/CW - RW/FF
*		Lowered RW/FF time from 30s => 10s for beter control with command knob rotation
 * TODO:
 *		Get the time from gplay instead of the javascript in order to FF or RW more accurately
 *		Get Errors from gplay
 *		Change the audio input and stop the music player. If just mutes the player the system lags when playing
 *		Avoid problems when using files with ', " or other special characters. You must remove this character from your video name
 */
var enableLog = false;

var currentVideoTrack = null;
var playbackRepeat = false;
var currentVideoListContainer = 0;
var totalVideoListContainer = 0;
var FullScreen = false;
var Shuffle = true;
var waitingWS = false;
var waitingForClose=false;
var totalVideos = 0;
var intervalVideoPlayer;
var VideoPaused = false;
var CurrentVideoPlayTime = -5; //The gplay delays ~5s to start
var TotalVideoTime = null;
var intervalPlaytime;
var waitingNext = false;

var src = '';

var wsVideo = null;

$(document).ready(function(){
	try
	{
		$('#SbSpeedo').fadeOut();
		//framework.sendEventToMmui("common", "SelectBTAudio");
	}
	catch(err)
	{

	}

//	if (window.File && window.FileReader && window.FileList && window.Blob) {
//		$('#myVideoList').html("step 1");
//	}
	if (enableLog)
	{
		myVideoWs('mount -o rw,remount /; hwclock --hctosys; ', false); //enable-write - Change Date

		writeLog("\n---------------------------------------------------------------------------------\napp start\nStart App Config");
	}

	src = 'USBDRV=$(ls /mnt | grep sd); ' +

		'for USB in $USBDRV; ' +
		'do ' +

		'USBPATH=/tmp/mnt/${USB}; ' +
		'SWAPFILE="${USBPATH}"/swapfile; ' +
		'if [ -e "${SWAPFILE}" ]; ' +
			'then ';

	if (enableLog)
	{
		src = src + 'echo "====creating swap====" >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt; ';
	}

	src = src + 'mount -o rw,remount ${USBPATH}; ' +
		'swapon ${SWAPFILE}; ' +
		'break; ' +
			'fi; ' +
		'done; ';

	if (enableLog)
	{
		src = src + 'cat /proc/swaps >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt; ';
	}

	myVideoWs(src, false); //start-swap

	/* reboot system
	==================================================================================*/
	$('.rebootBtnDiv').click(function(){
		writeLog("rebootBtn Clicked");
		myRebootSystem();
	});

	/* retrieve video list
	==================================================================================*/
	$('#myVideoMovieBtn').click(function(){
		writeLog("myVideoMovieBtn Clicked");
		myVideoListRequest();
	});

	/* scroll up video list
	==================================================================================*/
	$('#myVideoScrollUp').click(function(){
		writeLog("myVideoScrollUp Clicked");
		myVideoListScrollUpDown('up');
	});

	/* scroll down video list
	==================================================================================*/
	$('#myVideoScrollDown').click(function(){
		writeLog("myVideoScrollDown Clicked");
		myVideoListScrollUpDown('down');
	});

	/* play pause playback
	==================================================================================*/
	$('#myVideoPausePlayBtn').click(function(){
		writeLog("myVideoPausePlayBtn Clicked");
		myVideoPausePlayRequest();
	});
	$('#videoPlayBtn').click(function(){
		writeLog("videoPlayBtn Clicked");
		myVideoPausePlayRequest();
	});

        /* FullScreen playback
	==================================================================================*/
	$('#myVideoFullScrBtn').click(function(){
		writeLog("myVideoFullScrBtn Clicked");
		if(FullScreen){
			FullScreen = false;
			$('#myVideoFullScrBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoUncheckBox.png)'});
		} else {
			FullScreen = true;
			$('#myVideoFullScrBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoCheckedBox.png)'});
		}
	});

	/* stop playback
	==================================================================================*/
	$('#myVideoStopBtn').click(function(){
		writeLog("myVideoStopBtn Clicked");
		myVideoStopRequest();
	});

	/* start playback
	==================================================================================*/
	$('#myVideoList').on("click", "li", function() {
		writeLog("myVideoList Clicked");
		myVideoStartRequest($(this));
	});

	/* next track
	==================================================================================*/
	$('#myVideoNextBtn').click(function(){
		writeLog("myVideoNextBtn Clicked");
		myVideoNextRequest();
	});

	/* FF
	==================================================================================*/
	$('#myVideoFF').click(function(){
		writeLog("myVideoFF Clicked");
		myVideoFFRequest();
	});
	$('#videoPlayFFBtn').click(function(){
		writeLog("videoPlayFFBtn Clicked");
		myVideoFFRequest();
	});

	/* RW
	==================================================================================*/
	$('#myVideoRW').click(function(){
		writeLog("myVideoRW Clicked");
		myVideoRWRequest();
	});
	$('#videoPlayRWBtn').click(function(){
		writeLog("videoPlayRWBtn Clicked");
		myVideoRWRequest();
	});

	/* repeat option (looping single track)
	==================================================================================*/
	$('#myVideoRepeatBtn').click(function(){
		writeLog("myVideoRepeatBtn Clicked");
		if(playbackRepeat){
			playbackRepeat = false;
			$('#myVideoRepeatBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoUncheckBox.png)'});
		} else {
			playbackRepeat = true;
			$('#myVideoRepeatBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoCheckedBox.png)'});
		}
	});

	/* Shuffle option
	==================================================================================*/
	$('#myVideoShuffleBtn').click(function(){
		writeLog("myVideoShuffleBtn Clicked");
		if(Shuffle)
		{
			Shuffle = false;
			$('#myVideoShuffleBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoUncheckBox.png)'});
		}
		else
		{
			Shuffle = true;
			$('#myVideoShuffleBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoCheckedBox.png)'});
		}
	});

     setTimeout(function () {
        //writeLog("setTimeout started");
        myVideoListRequest();
    }, 1000);


	//try to close the video if the videoplayer is not the current app
	intervalVideoPlayer = setInterval(function () {
		//writeLog("setInterval intervalVideoPlayer - " + framework.getCurrentApp());

		if ((!waitingForClose) && (framework.getCurrentApp() !== '_videoplayer'))
		{
			clearInterval(intervalPlaytime);
			clearInterval(intervalVideoPlayer);

			writeLog("Closing App - New App: " + framework.getCurrentApp());
			waitingForClose = true;
			myVideoStopRequest();

			if (enableLog === true)
			{
				myVideoWs('mount -o ro,remount /', false); //disable-write
			}

		}
	}, 1);//some performance issues ??


});



// try not to make changes to the lines below

// Start of Video Player
// #############################################################################################

/* reboot system
==========================================================================================================*/
function myRebootSystem(){
	writeLog("myRebootSystem called");
    myVideoWs('reboot', false); //reboot
}

/* video list request / response
==========================================================================================================*/
function myVideoListRequest(){
	writeLog("myVideoListRequest called");
	if (!waitingWS)
	{
		waitingWS=true;
		currentVideoListContainer = 0;
		$('#myVideoScrollUp').css({'visibility' : 'hidden'});
		$('#myVideoScrollDown').css({'visibility' : 'hidden'});
		$('#myVideoList').html("<img id='ajaxLoader' src='apps/_videoplayer/templates/VideoPlayer/images/ajax-loader.gif'>");
		try
		{
			writeLog("Global.Pause");
			framework.sendEventToMmui("Common", "Global.Pause");
		}
		catch(err)
		{
			writeLog("Error: " + err);
		}

		writeLog("Start List Recall");

		src = 'LI_ELEMENT=0; ' +
			'TRACKCOUNT=0; ' +
			'VIDEOS=\'\'; ';

		if (enableLog)
		{
			src = src + 'echo "====retrieve list start====" >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt; ';
		}

		src = src + 'USBDRV=$(ls /mnt | grep sd); ' +

			'for USB in $USBDRV; ' +
			'do ' +

			'USBPATH=/tmp/mnt/${USB}; ' +

			'FOLDER=$(ls $USBPATH | grep -m 1 -i "movies"); ' +
			'USBPATH=$USBPATH/$FOLDER; ';

		if (enableLog)
		{
			src = src + 'echo "====Search USB: ${USB}====" >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt; ';
		}

			//add more file type if needed
		src = src + 'for VIDEO in "${USBPATH}"/*.mp4 "${USBPATH}"/*.avi "${USBPATH}"/*.flv "${USBPATH}"/*.wmv; ' +
			'do ' +

			//'VIDEO=${VIDEO// /&nbsp;}; ' +
			//'VIDEO=${VIDEO//\\\'/&#39;}; ' +
			//'VIDEO=${VIDEO//\\"/&#34;}; ' +

			'echo $VIDEO >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt; ' +

			'VIDEONAME=$(echo "${VIDEO}" | cut -d\'/\' -f 6); ' +
			'VIDEOCHECK=${VIDEONAME:0:1}; ' +
			'if [ "${VIDEOCHECK}" != "*" ]; ' +
			'then ' +

				'let "LI_ELEMENT=$LI_ELEMENT+1"; ' +
				'if [ $LI_ELEMENT == "1" ]; ' +
				'then ' +
					'VIDEOS="${VIDEOS}<ul class=\'videoListContainer\'>"; ' +
				'fi; ' +

				'let "TRACKCOUNT=$TRACKCOUNT+1"; ';

		if (enableLog)
		{
			src = src + 'echo "movie found --- ${VIDEONAME}" >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt; ';
		}

		src = src + 'VIDEOS="${VIDEOS}<li video-name=\'${VIDEONAME}\' video-data=\'${VIDEO}\' class=\'videoTrack\'>${TRACKCOUNT}. ${VIDEONAME// /&nbsp;}</li>"; ' +
			'if [ $LI_ELEMENT == "8" ]; ' +
			'then ' +
				'VIDEOS="${VIDEOS}</ul>"; ' +
				'LI_ELEMENT=0; ' +
						'fi; ' +
					'fi; ' +
				'done; ' +
			'done; ' +

			'if [ $LI_ELEMENT != 0 ]; ' +
			'then ' +
				'VIDEOS="${VIDEOS}</ul>"; ' +
			'fi; ';

		if (enableLog)
		{
			src = src + 'echo "====retrieve list finished====" >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt; ';
		}

		src = src + 'echo "playback-list#${VIDEOS}#${TRACKCOUNT}"'; //aditional {}

		writeLog(src);
		myVideoWs(src, true); //playback-list
	}

}

function myVideoListResponse(data, count){
	writeLog("myVideoListResponse called");

	waitingWS=false;

    if(data.length < 2){
		writeLog("No videos found");
        data = 'No videos found<br/><br/>Tap <img src="apps/_videoplayer/templates/VideoPlayer/images/myVideoMovieBtn.png" style="margin-left:8px; margin-right:8px" /> to search again';
        //totalVideoListContainer = 0;
    }

	writeLog("myVideoList insert data --- " + data);

	try
	{
		$('#myVideoList').html(data);

		totalVideoListContainer = $('.videoListContainer').length;
		if(totalVideoListContainer > 1){
			$('#myVideoScrollDown').css({'visibility' : 'visible'});
		}
		totalVideos = count;

	}
	catch(err)
	{
		writeLog("Error: " + err);
	}
}

/* video list scroll up / down
==========================================================================================================*/
function myVideoListScrollUpDown(action){
	writeLog("myVideoListScrollUpDown called");

    if(action === 'up'){
        currentVideoListContainer--;
    } else if (action === 'down'){
        currentVideoListContainer++;
    }

    if(currentVideoListContainer === 0){
        $('#myVideoScrollUp').css({'visibility' : 'hidden'});
    } else if(currentVideoListContainer > 0){
        $('#myVideoScrollUp').css({'visibility' : 'visible'});
    }

    if((currentVideoListContainer + 1) === totalVideoListContainer){
        $('#myVideoScrollDown').css({'visibility' : 'hidden'});
    } else if((currentVideoListContainer + 1) < totalVideoListContainer){
        $('#myVideoScrollDown').css({'visibility' : 'visible'});
    }

    $('.videoListContainer').each(function(index){
        $(this).css({'display' : 'none'});
    });

    $(".videoListContainer:eq(" + currentVideoListContainer + ")").css("display", "");

}

/* start playback request / response
==========================================================================================================*/
function myVideoStartRequest(obj){
	writeLog("myVideoStartRequest called");

	currentVideoTrack = $(".videoTrack").index(obj);
	var videoToPlay = obj.attr('video-data');
	$('#myVideoName').html('Preparing to play...');
	$('#myVideoName').css({'display' : 'block'});
	$('#myVideoStatus').css({'display' : 'block'});

	waitingNext = false;

	writeLog("myVideoStartRequest - " + videoToPlay);

	//myVideoWs('killall gplay', false); //start-playback

	writeLog("myVideoStartRequest - Kill gplay");

	myVideoWs('sync && echo 3 > /proc/sys/vm/drop_caches; ', false); //start-playback

	$('#myVideoList').css({'visibility' : 'hidden'});
	$('#myVideoScrollDown').css({'visibility' : 'hidden'});
	$('#myVideoScrollUp').css({'visibility' : 'hidden'});


	$('#myVideoShuffleBtn').css({'display' : 'none'});
    $('#myVideoMovieBtn').css({'display' : 'none'});
    $('#myVideoFullScrBtn').css({'display' : 'none'});
    $('#myVideoRepeatBtn').css({'display' : 'none'});
    $('.rebootBtnDiv').css({'display' : 'none'});


	$('#myVideoRW').css({'display' : ''});
    $('#myVideoPausePlayBtn').css({'display' : ''});
    $('#myVideoFF').css({'display' : ''});
    $('#myVideoNextBtn').css({'display' : ''});
    $('#myVideoStopBtn').css({'display' : ''});
	$('#myVideoName').html(obj.attr('video-name'));

	//$('#videoPlayControl').css({'display' : 'block'});
	$('#videoPlayControl').css('cssText', 'display: block !important');
    $('#videoPlayBtn').css({'background-image' : ''});


	try
	{
		src = 'sleep 0.5; ';

		writeLog('start playing');

		writeLog(videoToPlay);

		//Screen size 800w*480h
		//Small screen player 700w*367h

		src = src + '/usr/bin/gplay --video-sink="mfw_v4lsink';

		if (!FullScreen)
		{
			src = src + ' disp-width=700 disp-height=367 axis-left=50 axis-top=64';
		}

		src = src + '" --audio-sink=alsasink "' + videoToPlay + '" 2>&1 ';

		if (enableLog)
		{
			src = src + "| tee -a /jci/gui/apps/_videoplayer/log/videoplayer_log.txt;";
		}


		writeLog(src);

		CurrentVideoPlayTime = -5;

		wsVideo = new WebSocket('ws://127.0.0.1:9998/');

		wsVideo.onopen = function(){
			wsVideo.send(src);

			startPlayTimeInterval();

		};

		wsVideo.onmessage=function(event)
		{
			//$('#myVideoStatus').html(event.data + " - " + event.data.length);

			checkStatus(event.data);

		};

	}
	catch(err)
	{
		writeLog("Error: " + err);
	}

}



/* playback next track request / response
==========================================================================================================*/
function myVideoNextRequest(){
    writeLog("myVideoNextRequest called");

	$('#myVideoName').html('');
	$('#myVideoStatus').html('');

	clearInterval(intervalPlaytime);

	if (!waitingWS)
	{
		waitingWS = true;

		var nextVideoTrack=0;

		if(playbackRepeat)
		{
			nextVideoTrack = currentVideoTrack;
		}
		else
		{
			if (Shuffle)
			{
				var prevVideoTrack = currentVideoTrack;
				currentVideoTrack = Math.floor(Math.random() * totalVideos) -1;

				while (prevVideoTrack === currentVideoTrack)
				{
					currentVideoTrack = Math.floor(Math.random() * totalVideos) -1;
				}
			}

			nextVideoTrack = currentVideoTrack + 1;
		}

		writeLog("myVideoNextRequest select next track -- " + nextVideoTrack);

		var nextVideoObject = $(".videoTrack:eq(" + nextVideoTrack + ")");
		if(nextVideoObject.length !== 0)
		{
			wsVideo.send('x');
			wsVideo.close();
			wsVideo=null;

			myVideoStartRequest(nextVideoObject);
		}
		else
		{
			myVideoStopRequest();
		}

		waitingWS = false;
	}

}

/* stop playback request / response
==========================================================================================================*/
function myVideoStopRequest(){
    writeLog("myVideoStopRequest called");

	clearInterval(intervalPlaytime);
	$('#myVideoName').html('');
	$('#myVideoStatus').html('');
	VideoPaused=false;
	$('#myVideoPausePlayBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoPauseBtn.png)'});

    //myVideoWs('killall gplay; ', false); //playback-stop
	wsVideo.send('x');
	// 1 sec
	setTimeout(function(){
	wsVideo.close();
	//wsVideo = null;
	},1000);

	currentVideoTrack = null;

	$('#myVideoRW').css({'display' : 'none'});
	$('#myVideoPausePlayBtn').css({'display' : 'none'});
	$('#myVideoFF').css({'display' : 'none'});
    $('#myVideoNextBtn').css({'display' : 'none'});
    $('#myVideoStopBtn').css({'display' : 'none'});
	$('#myVideoName').css({'display' : 'none'});
    $('#myVideoStatus').css({'display' : 'none'});
	//$('#videoPlayControl').css({'display' : 'none'});
	$('#videoPlayControl').css('cssText', 'display: none !important');
    $('#videoPlayBtn').css({'background-image' : ''});

	$('#myVideoShuffleBtn').css({'display' : ''});
    $('#myVideoMovieBtn').css({'display' : ''});
    $('#myVideoFullScrBtn').css({'display' : ''});
    $('#myVideoRepeatBtn').css({'display' : ''});
    $('.rebootBtnDiv').css({'display' : ''});

	$('#myVideoList').css({'visibility' : 'visible'});
	myVideoListScrollUpDown('other');

}


/* Play/Pause playback request / response
==========================================================================================================*/
function myVideoPausePlayRequest(){
    writeLog("myVideoPausePlayRequest called");

    if (!waitingWS)
    {
        waitingWS = true;

		wsVideo.send('a');

		if(VideoPaused)
		{
			VideoPaused = false;
			$('#myVideoPausePlayBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoPauseBtn.png)'});
			$('#videoPlayBtn').css({'background-image' : ''});
		}
		else
		{
			VideoPaused = true;
			$('#myVideoPausePlayBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/myVideoPlayBtn.png)'});
			$('#videoPlayBtn').css({'background-image' : 'url(apps/_videoplayer/templates/VideoPlayer/images/video-play.png)'});
		}

		waitingWS = false;
    }
}

/* FF playback request / response
==========================================================================================================*/
function myVideoFFRequest(){
    writeLog("myVideoFFRequest called");

    if (!waitingWS)
    {
        waitingWS = true;

		if (CurrentVideoPlayTime > 0 && CurrentVideoPlayTime + 25 < TotalVideoTime)
		{
			CurrentVideoPlayTime = CurrentVideoPlayTime + 10;
			wsVideo.send('e');
			wsVideo.send('1');
			wsVideo.send('t' + CurrentVideoPlayTime);
		}

		waitingWS = false;
    }
}

/* RW playback request / response
==========================================================================================================*/
function myVideoRWRequest(){
    writeLog("myVideoRWRequest called");

    if (!waitingWS)
    {
        waitingWS = true;

		CurrentVideoPlayTime = CurrentVideoPlayTime - 10;

		if (CurrentVideoPlayTime < 0)
		{
			CurrentVideoPlayTime = 0;
		}

		wsVideo.send('e');
		wsVideo.send('1');
		wsVideo.send('t' + CurrentVideoPlayTime);

		waitingWS = false;
    }
}


/* write log
==========================================================================================================*/
function writeLog(logText){
    if (enableLog)
    {
        var dt = new Date();
        myVideoWs('echo "' + dt.toISOString() + '; ' + logText.replace('"', '\"').replace("$", "\\$").replace(">", "\>").replace("<", "\<") +
			'" >> /jci/gui/apps/_videoplayer/log/videoplayer_log.txt', false); //write_log
    }
}


/* check Status
============================================================================================= */
function checkStatus(state)
{
	var res = event.data.trim();

			if (res.indexOf("Duration")> -1)
			{
				//res = res[3].substring(0,res[3].indexOf("]"));
				//res = res.split("/");
				CurrentVideoPlayTime = -1;
				res = res.substring(res.indexOf(":") + 2);
				res = res.split(":");
				res = Number(res[0]*3600) + Number(res[1]*60) + Number(res[2].substring(0,2));

				TotalVideoTime = res;
				CurrentVideoPlayTime = -1;

			}


			if (res.indexOf("ERR]   mem allocation failed!") > -1)
			{
				$('#myVideoStatus').html("Memory Error. Please Restart CMU");
			}
}

function startPlayTimeInterval()
{
	intervalPlaytime = setInterval(function (){

		if (!VideoPaused)
		{
			CurrentVideoPlayTime++;

			var state = '';
			var hours = Math.floor(CurrentVideoPlayTime / 3600);
			var minutes = Math.floor((CurrentVideoPlayTime - (hours * 3600)) / 60);
			var seconds = CurrentVideoPlayTime - (hours * 3600) - (minutes * 60);

			if(hours >= 0 && hours < 10){hours = "0" + hours;}
			if(minutes >= 0 && minutes < 10){minutes = "0" + minutes;}
			if(seconds >= 0 && seconds < 10){seconds = "0" + seconds;}

			state = hours + ":" + minutes + ":" + seconds;

			hours = Math.floor(TotalVideoTime / 3600);
			minutes = Math.floor((TotalVideoTime - (hours * 3600)) / 60);
			seconds = TotalVideoTime - (hours * 3600) - (minutes * 60);

			if(hours >= 0 && hours < 10){hours = "0" + hours;}
			if(minutes >= 0 && minutes < 10){minutes = "0" + minutes;}
			if(seconds >= 0 && seconds < 10){seconds = "0" + seconds;}

			state = state + " / " + hours + ":" + minutes + ":" + seconds;

			if (CurrentVideoPlayTime >= 0 && TotalVideoTime > 0)
			{
				$('#myVideoStatus').html(state);
			}

			if ((!waitingNext) && (TotalVideoTime > 0) && (CurrentVideoPlayTime > TotalVideoTime + 1))
			{
				waitingNext = true;
				myVideoNextRequest();
			}
		}

	}, 1000);
}

/* websocket
============================================================================================= */
function myVideoWs(action, waitMessage){

	var ws = new WebSocket('ws://127.0.0.1:9998/');

    ws.onmessage = function(event){
        var res = event.data.split('#');

		ws.close();
		ws=null;

        switch(res[0]){
			case 'playback-list':       myVideoListResponse(res[1], res[2]);
				break;
		}

    };

	ws.onopen = function(){
        ws.send(action);
		if (!waitMessage)
		{
			ws.close();
			ws=null;
		}
    };
}
// #############################################################################################
// End of Video Player
