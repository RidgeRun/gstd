/**
* Copyright (C) 2009 Ridgerun (http://www.ridgerun.com). 
*
* This source code has a dual license.  If this file is linked with other
* source code that has a GPL license, then this file is licensed with a GPL
* license as described below.  Otherwise the source code contained in this
* file is property of Ridgerun. This source code is protected under
* copyright law.
*
* This program is free software; you can redistribute  it and/or modify it
* under  the terms of  the GNU General  Public License as published by the
* Free Software Foundation;  either version 2 of the  License, or (at your
* option) any later version.
*
* THIS  SOFTWARE  IS  PROVIDED  ``AS  IS''  AND   ANY  EXPRESS  OR IMPLIED
* WARRANTIES,   INCLUDING, BUT NOT  LIMITED  TO, THE IMPLIED WARRANTIES OF
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN
* NO  EVENT  SHALL   THE AUTHOR  BE    LIABLE FOR ANY   DIRECT,  INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED   TO, PROCUREMENT OF  SUBSTITUTE GOODS  OR SERVICES; LOSS OF
* USE, DATA,  OR PROFITS; OR  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
* ANY THEORY OF LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
* THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
* You should have received a copy of the  GNU General Public License along
* with this program; if not, write  to the Free Software Foundation, Inc.,
* 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#ifndef INCLUDE_COMMON_DEFS_H
#define INCLUDE_COMMON_DEFS_H

 /**
 * This file includes the common symbolic defines for both dbus-client and
 * the harrier-server
 */

/* Well-known name for this service. */
#define HARRIER_SERVICE_NAME        "com.ti.sdo.HarrierService"
/* Object path to the provided object. */
#define HARRIER_SERVICE_OBJECT_PATH "/com/ti/sdo/HarrierObject"
/* And we're interested in using it through this interface.
   This must match the entry in the interface definition XML. */
#define HARRIER_SERVICE_INTERFACE   "com.ti.sdo.HarrierInterface"

/* Symbolic constants for the signal names to use with GLib.
   These need to map into the D-Bus signal names. */
#define SIGNAL_DYING    "Dying"

#endif

