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

#ifndef DEFINE_HARRIER_H
#define DEFINE_HARRIER_H

#define HARRIER_TYPE_OBJECT (harrier_object_get_type())

#define HARRIER_OBJECT(object) \
        (G_TYPE_CHECK_INSTANCE_CAST((object), \
         HARRIER_TYPE_OBJECT, HarrierVrObject))
#define HARRIER_OBJECT_CLASS(klass) \
        (G_TYPE_CHECK_CLASS_CAST((klass), \
         HARRIER_TYPE_OBJECT, HarrierVrObjectClass))
#define HARRIER_IS_OBJECT(object) \
        (G_TYPE_CHECK_INSTANCE_TYPE((object), \
         HARRIER_TYPE_OBJECT))
#define HARRIER_IS_OBJECT_CLASS(klass) \
        (G_TYPE_CHECK_CLASS_TYPE((klass), \
         HARRIER_TYPE_OBJECT))
#define HARRIER_OBJECT_GET_CLASS(obj) \
        (G_TYPE_INSTANCE_GET_CLASS((obj), \
         HARRIER_TYPE_OBJECT, HarrierVrObjectClass))

#define MAX_NUM_ELEMENTS       100

//defines to indicate the type of stream to be recorded or played

#define AUDIO 1
#define VIDEO 2


//defines used to indicate the state of the recording or the playback

#define PLAY 1
#define PAUSE 2
#define STOP 3

//defines used to indicate the type of the pipeline to be built

#define RECORD 1
#define PLAYBACK 2

#endif
