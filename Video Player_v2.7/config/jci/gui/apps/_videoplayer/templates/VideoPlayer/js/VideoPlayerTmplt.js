/*
 Copyright 2016 Herko ter Horst
 __________________________________________________________________________

 Filename: VideoPlayerTmplt.js
 __________________________________________________________________________
 */

log.addSrcFile("VideoPlayerTmplt.js", "videoplayer");

/*
 * =========================
 * Constructor
 * =========================
 */
function VideoPlayerTmplt(uiaId, parentDiv, templateID, controlProperties)
{
    this.divElt = null;
    this.templateName = "VideoPlayerTmplt";

    this.onScreenClass = "VideoPlayerTmplt";

    log.debug("  templateID in VideoPlayerTmplt constructor: " + templateID);

    //@formatter:off
    //set the template properties
    this.properties = {
        "statusBarVisible" : true,
        "leftButtonVisible" : false,
        "rightChromeVisible" : false,
        "hasActivePanel" : true,//changed
        "isDialog" : false
    };
    //@formatter:on

    // create the div for template
    this.divElt = document.createElement('div');
    this.divElt.id = templateID;
    this.divElt.className = "TemplateFull VideoPlayerTmplt";

    parentDiv.appendChild(this.divElt);

    // do whatever you want here
                //var script1 = document.createElement("script");
    this.divElt.innerHTML = '<div id="myVideoContainer">'+
	'<div id="myVideoControlDiv">'+
	'<ul>'+
	'<li id="myVideoStopBtn" style="display: none; background-image: url(apps/_videoplayer/templates/VideoPlayer/images/myVideoStopBtn.png)"></li>'+
	'<li id="myVideoNextBtn" style="display: none; background-image: url(apps/_videoplayer/templates/VideoPlayer/images/myVideoNextBtn.png)"></li>'+
	'<li id="myVideoFF" style="display: none; background-image: url(apps/_videoplayer/templates/VideoPlayer/images/FF.png)"></li>'+
	'<li id="myVideoPausePlayBtn" style="display: none; background-image: url(apps/_videoplayer/templates/VideoPlayer/images/myVideoPauseBtn.png)"></li>'+
	'<li id="myVideoRW" style="display: none; background-image: url(apps/_videoplayer/templates/VideoPlayer/images/RW.png)"></li>'+
	'<li id="myVideoMovieBtn" style="background-image: url(apps/_videoplayer/templates/VideoPlayer/images/myVideoMovieBtn.png)"><a>Search Videos</a></li>'+
	'<li id="myVideoFullScrBtn" style="background-image: url(apps/_videoplayer/templates/VideoPlayer/images/myVideoUncheckBox.png)"><a>Full Screen</a></li>' +
	'<li id="myVideoRepeatBtn" style="background-image: url(apps/_videoplayer/templates/VideoPlayer/images/myVideoUncheckBox.png)"><a>Repeat 1</a></li>'+
	'<li id="myVideoShuffleBtn" style="background-image: url(apps/_videoplayer/templates/VideoPlayer/images/myVideoCheckedBox.png)"><a>Shuffle</a></li>'+
	'<li class="rebootBtnDiv" style="float:left !important; background-image: url(apps/_videoplayer/templates/VideoPlayer/images/rebootSys.png)"></li>'+
	'</ul>'+
	'<div id="myVideoName" style="font-style:italic"></div>'+
	'<div id="myVideoStatus" style="font-style:italic"></div></div>'+
	'<div id="myVideoList"></div>'+
	'<div id="myVideoScroll">'+
	'<img src="apps/_videoplayer/templates/VideoPlayer/images/myVideoUpBtn.png" id="myVideoScrollUp" />'+
	'<img src="apps/_videoplayer/templates/VideoPlayer/images/myVideoDownBtn.png" id="myVideoScrollDown" />'+
	'</div>'+
	'<div id="videoPlayControl">'+
	'<ul>'+
	'<li id="videoPlayRWBtn"></li>'+
	'<li id="videoPlayBtn"></li>'+
	'<li id="videoPlayFFBtn"></li>'+
	'</ul>'+
	'</div>'+
	'</div>'+
	'<script src="addon-common/jquery.min.js" type="text/javascript"></script>'+
	'<script src="apps/_videoplayer/js/videoplayer-v2.js" type="text/javascript"></script>';
}

/*
 * =========================
 * Standard Template API functions
 * =========================
 */

/* (internal - called by the framework)
 * Handles multicontroller events.
 * @param   eventID (string) any of the “Internal event name” values in IHU_GUI_MulticontrollerSimulation.docx (e.g. 'cw',
 * 'ccw', 'select')
 */
VideoPlayerTmplt.prototype.handleControllerEvent = function(eventID)
{
    log.debug("handleController() called, eventID: " + eventID);

    var retValue = 'giveFocusLeft';
    return retValue;
};
/*
 * Called by the app during templateNoLongerDisplayed. Used to perform garbage collection procedures on the template and
 * its controls.
 */
VideoPlayerTmplt.prototype.cleanUp = function()
{
	var child = document.getElementById(this.divElt.id);
	child.parentNode.removeChild(child);
	
	this.divElt=null;
	child=null;
};

framework.registerTmpltLoaded("VideoPlayerTmplt");
