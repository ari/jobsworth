
var captions = ["",
  "Never forget another task.",
  "Organize your tasks how YOU want.",
  "Ever wonder what has been done lately?",
  "Your schedule at a glance.",
  "Classify your tasks and issues.",
  "Find the needle in the haystack.",
  "It's about time...",
  "Keep project related files accessible.",
  "Chat with coworkers."
];
var numimages = 9;
var currentimage = 1;

var preloader = [];

function preload() {
  for( i = 1; i <= numimages; i++ ) {
    preloader[i] = new Image();
    preloader[i].src = "/images/portal/screen_" + i + ".png";
  }
}

function previous_image() {
  currentimage = ( currentimage == 1 ) ? numimages  : currentimage - 1;
  load_image( currentimage );
}
function next_image() {
  currentimage = ( currentimage == numimages  ) ? 1 : currentimage + 1;
  load_image( currentimage );
}
function load_image(imagenum) {
  currentimage = imagenum;
  $('caption').innerHTML = captions[currentimage];
  $('screenshot').src = "/images/portal/screen_" + currentimage + ".png";
}
