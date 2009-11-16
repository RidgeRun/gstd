/* BSD License
 *
 * Copyright (c) 2009, RidgeRun LLC
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *     * Redistributions of source code must retain the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the RidgeRun nor the
 *       names of its contributors may be used to endorse or promote
 *       products derived from this software without specific prior
 *       written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY RIDGERUN LLC ''AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL RIDGERUN LLC BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * End BSD License
 */

#include <stdio.h>
#include <string.h>
#include <gst/gst.h>
#include <glib.h>
#include <dbus/dbus-glib.h>
#include <stdlib.h> 			/* exit, EXIT_FAILURE */
#include <unistd.h> 			/* daemon */


#include "harrier_common_defs.h"     //Symbolic constants shared between 
					// gui and vr, vr as server

#include "harrier_config_common_defs.h"	//Symbolic constants shared between 
					//config and vr, config as server

#include "harrier.h"			/*Defines and function prototypes*/




typedef struct {
  GObject parent;
  gint state;				/*state refers to: PLAY (1),PAUSE (2),STOP (3)*/
  gint stream;				/*stream refers to: AUDIO (1), VIDEO (2) */
} HarrierVrObject;


typedef struct {
  GObjectClass parent;
} HarrierVrObjectClass;



/*Defines*/

G_DEFINE_TYPE(HarrierVrObject, harrier_object, G_TYPE_OBJECT)
void create_audio_pipeline();
void create_pipeline(char str_pipeline[]);
void check_pipeline_type(HarrierVrObject* obj, gint stream);
void search_pipeline(int type,char** strpipe);

/*Function Prototypes*/
GType value_object_get_type(void);

gboolean harrier_object_recording(HarrierVrObject* obj, gint stream,
                                                  GError** error);
gboolean harrier_object_playing(HarrierVrObject* obj, gint stream,
                                                  GError** error);
gboolean harrier_object_change_state(HarrierVrObject* obj, gint state,
                                                  GError** error);


#include "harrier_server_stub.h"	// Defines and functions generated
					// by the binding-tools with the XML. 
					// This file has to be included after the function prototypes


/*Global Variables*/
  
  gboolean existing_pipeline = FALSE;
  
  GMainLoop* mainloop = NULL;
  
//  char str_pipe[];
 GstElement    *pipeline;
		/**source,
		*parser,
		*resample, 
		*demuxer,
		*decoder,
		*conv,
		*sink,
		*ffmpeg,
		*video_sink;*/
  //GstElement ** GstElementArray;
  GstBus *bus;


#ifdef NO_DAEMON
#define dbg(fmtstr, args...) \
  (g_print(PROGNAME ":%s: " fmtstr "\n", __func__, ##args))
#else
#define dbg(dummy...)
#endif


/************* GSTREAMER FUNCTIONS ******************/

static gboolean bus_call (GstBus     *bus,
        		  GstMessage *msg,
		          gpointer    data){


  GMainLoop *loop = (GMainLoop *) data;

  switch (GST_MESSAGE_TYPE (msg)) {

    case GST_MESSAGE_EOS:
      g_print ("End of stream\n");
      break;
 
    case GST_MESSAGE_ERROR: {
      gchar  *debug;
      GError *error;
 
      gst_message_parse_error (msg, &error, &debug);
      g_free (debug);
 
      g_printerr ("Error: %s\n", error->message);
      g_error_free (error);
      g_main_loop_quit (loop);
      break;
    }
    default:
      break;
  }

  return TRUE;
}



static void on_pad_added (GstElement *element,
                          GstPad     *pad,
                          gpointer    data){

  GstPad *sinkpad;
  GstElement *decoder = (GstElement *) data;
  
//  g_print ("Dynamic pad created, linking parser/decoder\n");
  sinkpad = gst_element_get_pad (decoder, "sink");
  gst_pad_link (pad, sinkpad);
  gst_object_unref (sinkpad);

} 



void create_audio_pipeline(){
}
/****This code has not been erase yet, because it is needed as reference***/

  //printf("\nCreating pipeline\n");

  /* Create gstreamer elements */
  
 /* pipeline = gst_pipeline_new ("audio-player");
  source   = gst_element_factory_make ("filesrc",       "file-source");
  decoder = gst_element_factory_make("mad", "mp3-decoder");
  conv     = gst_element_factory_make ("audioconvert",  "converter");
  resample = gst_element_factory_make ("audioresample", "audio-resampler");
  sink     = gst_element_factory_make ("alsasink", "alsa-output");
 
  if (!pipeline || !source // || !demuxer || !decoder || !conv || !resample || !sink) {
    g_printerr ("One element could not be created. Exiting.\n");
  }
*/
  /* Set up the pipeline */

  /* we set the input filename to the source element */
 // g_object_set (G_OBJECT (source), "location", "Michael.mp3", NULL);
 
  /* we add a message handler */
 // bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline));
 // gst_bus_add_watch (bus, bus_call, mainloop);
 // gst_object_unref (bus);
 
  /* we add all elements into the pipeline */
  /* file-source | ogg-demuxer | vorbis-decoder | converter | alsa-output */
  //gst_bin_add_many (GST_BIN (pipeline),
    //                source,/* demuxer,*/ decoder, conv, resample, sink, NULL);

  /* we link the elements together */
  /* file-source -> ogg-demuxer ~> vorbis-decoder -> converter -> alsa-output */
 // gst_element_link (source, decoder/*demuxer*/);
 // gst_element_link_many (source, decoder, conv, resample, sink, NULL);
  //g_signal_connect (decoder /*demuxer*/, "pad-added", G_CALLBACK (on_pad_added), NULL);
  
 // g_print("\nAudio pipeline has been created\n");

//}

// Struct recursive definition

struct _Token;

struct _Token {
    char* pipe_token;
    struct _Token* next;
};

typedef struct _Token TokenElement;

void addToken(TokenElement** ptr_list,TokenElement** ptr_last,int* ptr_token_count,const char * token){
    
    
    /*Asigning dinamic memory to the new linked list element*/
    TokenElement* new = (TokenElement*)malloc(sizeof(TokenElement));
    if(new == NULL) g_printerr ("Malloc to new failed. Exiting\n");
    
    /*Asigning dinamic memory to the parsed string*/
    new->pipe_token=(char *)malloc(strlen(token)+1);
    if(new->pipe_token == NULL) g_printerr ("Malloc to pipe_token failed. Exiting\n");
    
    /*Saving the parsed string on the new element*/
    strcpy(new->pipe_token,token);

    /*Adjusting pointers to link new element on the list*/
    if(!*ptr_token_count){

	new->next = NULL;
	*ptr_list = new;
	*ptr_last = *ptr_list;
    }
    else{

	(*ptr_last)->next = new;
	*ptr_last=new;
	new->next=NULL;
    }
    /*Count of elements added to the linked list*/
    (*ptr_token_count)++;
}

void freeTokenList (TokenElement** ptr_list, TokenElement** ptr_last){

    TokenElement * tmp;
    int count=0;
    

    if(*ptr_list == NULL) g_printerr ("Trying to free list without elements. Exiting\n");
    
    else{
        do{

            tmp = *ptr_list;
            *ptr_list = (*ptr_list)->next;
            free(tmp->pipe_token);
            free(tmp);
            count++;

        }while((*ptr_list)->next!=NULL);

        /*Freeing the last element*/
        free((*ptr_list)->pipe_token);
        free(*ptr_list);

        *ptr_list = *ptr_last = NULL;
    }
}

//Missing doxygen documentation

void create_pipeline(char* str_pipeline){

  char * str_handler;
  int index,index2,pipe_size;
  int tmp, num_properties;
  char element_name[2];

  TokenElement *list,*last;
  TokenElement *present,*future;
  int token_count = 0;
  
  
  g_print("\nCreating pipeline\n");
  
     //Check if there's a pipeline created and unreference it before creating a new one
    if(existing_pipeline) {
	g_print("\nUnreferencing the pipeline\n");
	gst_element_set_state(pipeline, GST_STATE_NULL);
	gst_object_unref (GST_OBJECT(pipeline));
	existing_pipeline = FALSE;
    }
  
  /* create Gstreamer pipeline*/
  pipeline   = gst_pipeline_new ("video-player");
  
  if (!pipeline) {
   g_printerr ("The pipeline could not be created. Exiting\n");
  }
  
  /* splitting str_pipeline into tokens*/
  str_handler = strtok (str_pipeline,"!");
  list = last = NULL;
  
  do{
    
    addToken(&list,&last,&token_count,str_handler);
    str_handler = strtok (NULL, "!");
  
  } while (str_handler!= NULL);

  /*pipeline size refers to the numbers of gst elements,we need 2 tokens per element*/
  pipe_size = token_count>>1;
  
  /*Declaration the gstreamer_elements array to build the pipeline*/
  GstElement* gst_element[pipe_size];
  
  /*Going over the Tokenlist to build the pipeline*/
  
  if (list==NULL) g_printerr ("Unable to parse profile. Exiting\n");
  else{
    
    /*pointers to go over the list*/
    present = list;
    future = present->next;
    index=0;
    

    while (index<pipe_size){
        
        /*index functions as name to the new element*/
        tmp = sprintf(element_name, "%d", index);
        if (!(tmp<MAX_NUM_ELEMENTS))g_printerr("Overrun number of elements");
        /*Creating the Gstreamer elements*/
        gst_element[index] = gst_element_factory_make(present->pipe_token,element_name);
        
        if (!gst_element[index]) {
             g_printerr ("The element number %i could not be created. Exiting\n",index);
        }
        
        /*Set properties for elements*/
        
        num_properties= atoi(future->pipe_token);
        if(num_properties!=0){

            for(index2=0;index2<num_properties;index2++){
                
                present = future->next;
                if (present!=NULL)future = present->next;
                index2++;
                pipe_size--;
                
                /*Setting properties*/
                g_object_set (G_OBJECT (gst_element[index]),present->pipe_token,future->pipe_token, NULL);
            }
        }    
        /*adding elements and linking them together*/
        gst_bin_add (GST_BIN (pipeline),gst_element[index]);
        if (index!=0)gst_element_link (gst_element[index-1], gst_element[index]);
        
        
        /*Advancing through the list,two elements*/
        present = future->next;
        if (present!=NULL)future = present->next;
        index++;
    }

  }
  
  /*Free memory*/
  freeTokenList(&list,&last);
 
  /* we add a message handler */
  bus = gst_pipeline_get_bus (GST_PIPELINE (pipeline));
  gst_bus_add_watch (bus, bus_call, mainloop);
  gst_object_unref (bus);

//  g_signal_connect (gst_element, "pad-added", G_CALLBACK (on_pad_added), decoder);
 
  g_print("\nVideo pipeline has been created\n");

}

/*Programmer must strpipe after using it*/
void search_pipeline(int type, char** strpipe){

    FILE* profile;
    int strlen = 0;
    char caracter = ' ';
    
    /*Open profile*/
    if(type==RECORD){
        profile = fopen("pipeline_record_profile","r");
        if (profile==NULL) g_printerr ("pipeline_record_profile could not be opened.Exiting\n");
    }
    
    else {
        profile = fopen("pipeline_playback_profile","r");
        if (profile==NULL)g_printerr("pipeline_playback_profile could not be opened.Exiting\n");
    }

    /*Calculating the string lenght*/
    while (caracter!='\n'&& !feof(profile)){
        if(fscanf(profile, "%c", &caracter))strlen++;
    }
    strlen++;
    
    /*Asigning dinamic memory space for the string*/
    *strpipe = (char *)malloc(strlen);
    if((*strpipe) == NULL) g_printerr ("Malloc to str_pipe failed. Exiting\n");

    /*Setting file-pointer at the benning*/
    fseek(profile, 0, SEEK_SET);
    
    /*Reading hole string*/
    if(fgets((*strpipe),strlen,profile) == NULL) g_printerr ("Profile empty!!.Exiting\n");
    
    /*Close profile*/
    fclose(profile);
}

/*********************HARRIER_OBJECT FUNCTIONS******************************/


/* Per object initializer */
static void harrier_object_init(HarrierVrObject* obj) {

  g_assert(obj != NULL);

  obj->stream = AUDIO;
  obj->state = PLAY;
}

/* Per class initializer*/
static void harrier_object_class_init(HarrierVrObjectClass* klass) {


  g_assert(klass != NULL);
  dbg("Binding to GLib/D-Bus");
  dbus_g_object_type_install_info(HARRIER_TYPE_OBJECT,
                                 &dbus_glib_harrier_object_object_info);


}

void check_pipeline_type(HarrierVrObject* obj, gint stream){
    
    //char str_pipe[];
    //Check if the pipeline that will be created is an audio pipeline or a video pipeline
    
    switch(stream){
	case 1:
	    //g_print("\nCreating an audio pipeline...\n");
	    obj->stream = AUDIO;
	    //create_audio_pipeline();
	    //existing_pipeline = TRUE;
	    
	break;
	
	case 2:
	    //g_print("\nCreating a video pipeline...\n");
	    obj->stream = VIDEO;
	    
	    //strcpy(str_pipe,"!filesrc!source!dvddemux!dvd-demuxer!mpeg2dec!video-decoder!ffmpegcolorspace!ffmpeg!xvimagesink!vsink");
	    //create_video_pipeline(str_pipe);
	    //g_print("Ready... out of the function0\n");
	    //existing_pipeline = TRUE;
	break;
	
	default:
	    g_print("\nError: This stream type does not belong to a definition.\n");
	    exit(EXIT_FAILURE);
	break;
    
    }

}

gboolean harrier_object_recording(HarrierVrObject* obj, gint stream,
                                                  GError** error){

    char* strpipe;
    
    /*Call the function that verifies what type of pipeline it is and create it.*/
    check_pipeline_type(obj, stream);
    
    /*Search the record pipeline,configured by the user on config module*/
    search_pipeline(RECORD,&strpipe);
    g_print("Pipeline record configuration requiered:%s\n",strpipe);
    
    /*Creating record pipeline*/
    create_pipeline(strpipe);
    
    free(strpipe);
    existing_pipeline = TRUE;
    
    return TRUE;

}
gboolean harrier_object_playing(HarrierVrObject* obj, gint stream,
                                                  GError** error){

    /**** ADD THE CALL TO search_playing_pipeline on harrier_config/ **/
    char* strpipe;
    
    /*Call the function that verifies what type of pipeline it is and create it.*/
    check_pipeline_type(obj, stream);
    
    /*Search the record pipeline,configured by the user on config module*/
    search_pipeline(PLAYBACK,&strpipe);
    g_print("Pipeline playback configuration requiered:%s\n",strpipe);
    
    /*Creating record pipeline*/
    create_pipeline(strpipe);
    
    free(strpipe);
    existing_pipeline = TRUE;
    
    return TRUE;

}


gboolean harrier_object_change_state(HarrierVrObject* obj, gint state,
                                                  GError** error){
    
    switch(state){
	case 1:
	    g_print("\nPlaying...\n");
	    obj->state = PLAY;
	    g_print("\nStream: %i\n", obj->stream);
	    g_print("\nState: %i\n", obj->state);
	    gst_element_set_state(pipeline, GST_STATE_PLAYING);
	break;
	
	case 2:
	    g_print("\nPaused...\n");
	    obj->state = PAUSE;
	    gst_element_set_state(pipeline, GST_STATE_PAUSED);
	break;
	
	case 3: 
	    g_print("\nStopped...\n");
	    obj->state = STOP;
	    gst_element_set_state(pipeline, GST_STATE_NULL);
	break;
	
	default:
	    g_print("\nError! You selected a non existing pipeline state.\n");
	    exit(EXIT_FAILURE);
	break;
    
    }
    return TRUE;
}



static void handleError(const char* msg, const char* reason,
                                         gboolean fatal) {
  g_printerr(PROGNAME ": ERROR: %s (%s)\n", msg, reason);
  if (fatal) {
    exit(EXIT_FAILURE);
  }
}
/*******************************************************************/

/**
 * The main server code
 *
 * 1) Init GType/GObject
 * 2) Create a mainloop
 * 3) Connect to the Session bus
 * 4) Get a proxy object representing the bus itself
 * 5) Register the well-known name by which clients can find us.
 * 6) Create one harrier object that will handle all client requests.
 * 7) Register it on the bus (will be found via "/GlobalValue" object
 *    path)
 * 8) Daemonize the process (if not built with NO_DAEMON)
 * 9) Start processing requests (run GMainLoop)
 *
 * This program will not exit (unless it encounters critical errors).
 */

int main(int argc, char** argv) {

  DBusGConnection* bus = NULL;
  DBusGProxy* busProxy = NULL;
  HarrierVrObject* harrierVrObj = NULL;

  guint result;
  GError* error = NULL;
  
  //Initialize GStreamer
  gst_init (&argc, &argv);

  g_type_init();

  mainloop = g_main_loop_new(NULL, FALSE);
  if (mainloop == NULL) {
    handleError("Couldn't create GMainLoop", "Unknown(OOM?)", TRUE);
  }

  g_print(PROGNAME ":main Connecting to the Session D-Bus.\n");
  bus = dbus_g_bus_get(DBUS_BUS_SESSION, &error);
  if (error != NULL) {
    handleError("Couldn't connect to session bus", error->message, TRUE);
  }

  g_print(PROGNAME ":main Registering the well-known name (%s)\n",
          HARRIER_SERVICE_NAME);

  busProxy = dbus_g_proxy_new_for_name(bus,
                                       DBUS_SERVICE_DBUS,
                                       DBUS_PATH_DBUS,
                                       DBUS_INTERFACE_DBUS);
  if (busProxy == NULL) {
    handleError("Failed to get a proxy for D-Bus",
                "Unknown(dbus_g_proxy_new_for_name)", TRUE);
  }

  if (!dbus_g_proxy_call(busProxy,
                         "RequestName",
                         &error,
                         G_TYPE_STRING,
                         HARRIER_SERVICE_NAME,
                         G_TYPE_UINT,
                         0,
                         G_TYPE_INVALID,
                         G_TYPE_UINT,
                         &result,
                         G_TYPE_INVALID)) {
    handleError("D-Bus.RequestName RPC failed", error->message,TRUE);
  }
  g_print(PROGNAME ":main RequestName returned %d.\n", result);
  if (result != 1) {
    handleError("Failed to get the primary well-known name.",
                "RequestName result != 1", TRUE);
  }

  g_print(PROGNAME ":main Creating one HarrierVr object.\n");
  harrierVrObj = g_object_new(HARRIER_TYPE_OBJECT, NULL);
  if (harrierVrObj == NULL) {
    handleError("Failed to create one Value instance.",
                "Unknown(OOM?)", TRUE);
  }
  

  g_print(PROGNAME ":main Registering it on the D-Bus.\n");
  dbus_g_connection_register_g_object(bus,
                                      HARRIER_SERVICE_OBJECT_PATH,
                                      G_OBJECT(harrierVrObj));

  g_print(PROGNAME ":main Ready to serve requests (daemonizing).\n");

#ifndef NO_DAEMON

  if (daemon(0, 0) != 0) {
    g_error(PROGNAME ": Failed to daemonize.\n");
  }
#else
  g_print(PROGNAME
          ": Not daemonizing (built with NO_DAEMON-build define)\n");
#endif

  g_main_loop_run(mainloop);
  
  gst_object_unref (GST_OBJECT(pipeline));
    
  return EXIT_FAILURE;
}
