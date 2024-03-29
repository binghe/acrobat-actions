/********************************************************************/
/*                                                                  */
/* ADOBE SYSTEMS INCORPORATED                                       */
/* Copyright 1986 - 2012 Adobe Systems Incorporated                 */
/* All Rights Reserved                                              */
/*                                                                  */
/* NOTICE:  Adobe permits you to use, modify, and distribute this   */
/* file in accordance with the terms of the Adobe license agreement */
/* accompanying it.  If you have received this file from a source   */
/* other than Adobe, then your use, modification, or distribution   */
/* of it requires the prior written permission of Adobe.            */
/*                                                                  */
/********************************************************************/

/*
 * Program Name:
 *	    Sample client for Hotspots in FrameMaker 11.
 *
 * Invocation:
 *		From the FDK Class Menu , choose "Get hotspot" , "Set hotspot" , "Delink hotspot
 *      and "Visual Indicator(On/Off)"
 *
 * General Description:
 *	    Get and Set hotspot properties by querying the inset's FP_IsHotspot,
 *      FP_HotspotCmdStr and FP_HotspotTitle property.
 *		Delink hotspot properties of a selected hotspot
 *      Toggling visual indicator for hotspot.
 *     
 *
 * Install Info (Windows):
 *		Add the following entry (all on one line) to the [APIClients]
 *		section of your maker.ini file:
 *
 *		views=Standard, Hotspots in FrameMaker 11,
 *			fdk_install_dir\samples\hotspot\debug\hotspot.dll, all 
 *
 *		Replace fdk_install_dir with the path of the directory
 *		in which you installed your copy of the FDK files.
 *		
 *      Restart maker.
 *
 *	Exceptions:
 *		None. 
 *
 ***********************************************************************/
#include "fapi.h"
#include "fdetypes.h"
#include "futils.h"
#include "fstrings.h"

#define Get_Hotspot_Properties 1
#define Set_Hotspot_Properties 2
#define Delink_Hotspot_Properties 3
#define Visual_Indicator 4
#define CMD (StringT)"message URL "

UCharT msg[256];  /* your message to the user */

/* Function prototype */
VoidT GetHotspotProperties(F_ObjHandleT docId);
VoidT SetHotspotProperties(F_ObjHandleT docId);
VoidT DelinkHotspotProperties(F_ObjHandleT docId);
VoidT TogglingVisualIndicator(F_ObjHandleT docId);


/* Call back to put up menu and command */
VoidT F_ApiInitialize(IntT init)
{
	F_ObjHandleT menuBarId,menuId;
		
	/* Making it unicode enabled. */
	F_FdeInit();
	F_ApiEnableUnicode(True);
  	F_FdeInitFontEncs("UTF-8");

	switch(init)
	{
	case FA_Init_First:
		
		menuBarId = F_ApiGetNamedObject(FV_SessionId, FO_Menu, (ConStringT)"!MakerMainMenu");
		menuId = F_ApiDefineAndAddMenu(menuBarId, (ConStringT)"Hotspot",(ConStringT) "Hotspot");

		F_ApiDefineAndAddCommand(Get_Hotspot_Properties, menuId, (ConStringT)"Get Hotspot Properties", (ConStringT)"Get Hotspot Properties", (ConStringT)"\\!ghp");
		F_ApiDefineAndAddCommand(Set_Hotspot_Properties, menuId, (ConStringT)"Set Hotspot Properties", (ConStringT)"Set Hotspot Properties", (ConStringT)"\\!shp");
		F_ApiDefineAndAddCommand(Delink_Hotspot_Properties, menuId, (ConStringT)"Delink Hotspot Properties", (ConStringT)"Delink Hotspot Properties", (ConStringT)"\\!dhp");
		F_ApiDefineAndAddCommand(Visual_Indicator, menuId, (ConStringT)"Visual Indicator(On/Off)", (ConStringT)"Visual Indicator(On/Off)", (ConStringT)"\\!vi");
		break;
	}
}

/* Callback to respond to the user choosing menu items */
VoidT F_ApiCommand(IntT command)
{
	F_ObjHandleT docId;

	docId = F_ApiGetId(0,FV_SessionId, FP_ActiveDoc);
	if (!docId)
		return;

	switch (command)
	{
		case Get_Hotspot_Properties: //Getting hotspot properties of a the selected hotspot
		GetHotspotProperties(docId);
		break;
		
		case Set_Hotspot_Properties: //Setting hotspot properties of the selected graphic object
		SetHotspotProperties(docId);
		break;
			
	    case Delink_Hotspot_Properties: //Delink a selected hotspot
		DelinkHotspotProperties(docId);
	    break;

		case Visual_Indicator:  //Toggling the hotspot visual indicator
		TogglingVisualIndicator(docId);
		break;
		
		default:
		break;
	}
}

VoidT GetHotspotProperties(F_ObjHandleT docId)
{
	StringT cmdString,tooltip;
	F_ObjHandleT hotspotId;

	hotspotId = F_ApiGetId(FV_SessionId, docId, FP_FirstSelectedGraphicInDoc); 
	    	
	if (hotspotId)
	{
		if (F_ApiGetInt(docId,hotspotId,FP_IsHotspot)) // if the selected graphics object is hotspot
		{
			cmdString=F_ApiGetString(docId,hotspotId,FP_HotspotCmdStr); //Getting the hotspot command
			tooltip=F_ApiGetString(docId,hotspotId,FP_HotspotTitle);   //Getting the hotspot tooltip
					
			F_Sprintf(msg, "Hotspots Properties: Command=%s Tooltip=%s",cmdString,tooltip);	
			F_ApiAlert((StringT)msg, FF_ALERT_CONTINUE_NOTE);
										
		}
		else
			F_ApiAlert((StringT)"Selected graphics object is not a hotspot", FF_ALERT_CONTINUE_NOTE);
	}
	else
			F_ApiAlert((StringT)"Please select a hotspot to get the properties", FF_ALERT_CONTINUE_NOTE);
}

VoidT SetHotspotProperties(F_ObjHandleT docId)
{
	F_ObjHandleT hotspotId;
	IntT err;
	StringT URL,cmdString,tooltip;
				
	hotspotId = F_ApiGetId(FV_SessionId, docId, FP_FirstSelectedGraphicInDoc);
	if (hotspotId)
	{
	err = F_ApiPromptString(&URL, (StringT)"Enter a URL",(StringT)"http://");
	cmdString=F_StrCopyString(CMD);
	F_StrCat(cmdString, (StringT)URL);
	err = F_ApiPromptString(&tooltip, (StringT)"Enter a Tooltip",(StringT)"");
	F_ApiSetInt(docId,hotspotId,FP_IsHotspot,True);                            
	F_ApiSetString(docId,hotspotId,FP_HotspotCmdStr,(ConStringT)cmdString);   //Setting the hotspot command
	F_ApiSetString(docId,hotspotId,FP_HotspotTitle,(ConStringT)tooltip);      //Setting the hotspot tooltip
	}
	else
		F_ApiAlert((StringT)"Please select a graphic to set the hotspot properties", FF_ALERT_CONTINUE_NOTE);

	F_ApiDeallocateString(&URL); 
	F_ApiDeallocateString(&tooltip); 
}

VoidT DelinkHotspotProperties(F_ObjHandleT docId)
{
	F_ObjHandleT hotspotId;
	
	hotspotId = F_ApiGetId(FV_SessionId, docId, FP_FirstSelectedGraphicInDoc);
	    	
	if (hotspotId)
	{
		if (F_ApiGetInt(docId,hotspotId,FP_IsHotspot))
		{
			F_ApiSetInt (0, hotspotId,	FP_IsHotspot,False);  //Delink the selected hotspot
			F_ApiAlert((StringT)"Selected hotspot is delinked",FF_ALERT_CONTINUE_NOTE);		
		}
		else
			F_ApiAlert((StringT)"Selected graphics object is not a hotspot", FF_ALERT_CONTINUE_NOTE);
	}
	else
		 F_ApiAlert((StringT)"Please select a hotspot to delink", FF_ALERT_CONTINUE_NOTE);
}

VoidT TogglingVisualIndicator(F_ObjHandleT docId)
{
	if(F_ApiGetInt (0, docId,	FP_ViewHotspotIndicators))
		F_ApiSetInt (0, docId,	FP_ViewHotspotIndicators,False);	
		else
		F_ApiSetInt (0, docId,	FP_ViewHotspotIndicators,True);
}
