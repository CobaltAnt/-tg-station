/datum/AI_Module
	var/uses = 0
	var/module_name
	var/mod_pick_name
	var/description = ""
	var/engaged = 0
	var/cost = 5
	var/one_time = 0

	var/power_type


/datum/AI_Module/large/
	uses = 1

/datum/AI_Module/small/
	uses = 5

//////DOOMSDAY DEVICE

/datum/AI_Module/large/nuke_station
	module_name = "Doomsday Device"
	mod_pick_name = "nukestation"
	description = "Activate a weapon that will disintegrate all organic life on the station after a 450 second delay."
	cost = 130
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/nuke_station

/mob/living/silicon/ai/proc/nuke_station()
	set category = "Malfunction"
	set name = "Doomsday Device"

	for(var/turf/simulated/floor/bluegrid/T in orange(5, src))
		T.icon_state = "rcircuitanim" //Causes blue tiles near the AI to change to flashing red

	src << "<span class='notice'>Nuclear device armed.</span>"
	priority_announce("Hostile runtimes detected in all station systems, please deactivate your AI to prevent possible damage to its morality core.", "Anomaly Alert", 'sound/AI/aimalf.ogg')
	set_security_level("delta")
	SSshuttle.emergencyNoEscape = 1
	nuking = 1
	var/obj/machinery/doomsday_device/DOOM = new /obj/machinery/doomsday_device(src)
	doomsday_device = DOOM
	verbs -= /mob/living/silicon/ai/proc/nuke_station
	for(var/obj/item/weapon/pinpointer/point in pinpointer_list)
		for(var/mob/living/silicon/ai/A in ai_list)
			if((A.stat != DEAD) && A.nuking)
				point.the_disk = A //The pinpointer now tracks the AI core

/obj/machinery/doomsday_device
	icon = 'icons/obj/machines/nuke_terminal.dmi'
	name = "doomsday device"
	icon_state = "nuclearbomb_base"
	desc = "A weapon which disintegrates all organic life in a large area."
	anchored = 1
	density = 1
	verb_exclaim = "blares"
	var/timing = 1
	var/timer = 450

/obj/machinery/doomsday_device/process()
	var/turf/T = get_turf(src)
	if(!T || T.z != ZLEVEL_STATION)
		minor_announce("DOOMSDAY DEVICE OUT OF STATION RANGE, ABORTING", "ERROR ER0RR $R0RRO$!R41.%%!!(%$^^__+ @#F0E4", 1)
		SSshuttle.emergencyNoEscape = 0
		if(SSshuttle.emergency.mode == SHUTTLE_STRANDED)
			SSshuttle.emergency.mode = SHUTTLE_DOCKED
			SSshuttle.emergency.timer = world.time
			priority_announce("Hostile environment resolved. You have 3 minutes to board the Emergency Shuttle.", null, 'sound/AI/shuttledock.ogg', "Priority")
		qdel(src)
	if(!timing)
		return
	if(timer <= 0)
		timing = 0
		detonate(T.z)
		qdel(src)
	else
		timer--
		if(!(timer%60))
			var/message = "[timer] SECONDS UNTIL DOOMSDAY DEVICE ACTIVATION!"
			minor_announce(message, "ERROR ER0RR $R0RRO$!R41.%%!!(%$^^__+ @#F0E4", 1)


/obj/machinery/doomsday_device/proc/detonate(z_level = 1)
	for(var/mob/M in player_list)
		M << 'sound/machines/Alarm.ogg'
	sleep(100)
	for(var/mob/living/L in mob_list)
		var/turf/T = get_turf(L)
		if(T.z != z_level)
			continue
		if(issilicon(L))
			continue
		L << "<span class='danger'><B>The blast wave from the [src] tears you atom from atom!</B></span>"
		L.dust()
	world << "<B>The AI cleansed the station of life with the doomsday device!</B>"
	ticker.force_ending = 1

/datum/AI_Module/large/fireproof_core
	module_name = "Core Upgrade"
	mod_pick_name = "coreup"
	description = "An upgrade to improve core resistance, making it immune to fire and heat. This effect is permanent."
	cost = 50
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/fireproof_core



//////END DOOMSDAY DEVICE


/mob/living/silicon/ai/proc/fireproof_core()
	set category = "Malfunction"
	set name = "Fireproof Core"
	for(var/mob/living/silicon/ai/ai in player_list)
		ai.fire_res_on_core = 1
	src.verbs -= /mob/living/silicon/ai/proc/fireproof_core
	src << "<span class='notice'>Core fireproofed.</span>"

/datum/AI_Module/large/upgrade_turrets
	module_name = "AI Turret Upgrade"
	mod_pick_name = "turret"
	description = "Improves the power and health of all AI turrets. This effect is permanent."
	cost = 30
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/upgrade_turrets

/mob/living/silicon/ai/proc/upgrade_turrets()
	set category = "Malfunction"
	set name = "Upgrade Turrets"

	if(!canUseTopic())
		return

	src.verbs -= /mob/living/silicon/ai/proc/upgrade_turrets
	//Upgrade AI turrets around the world
	for(var/obj/machinery/porta_turret/ai/turret in machines)
		turret.health += 30
		turret.eprojectile = /obj/item/projectile/beam/heavylaser //Once you see it, you will know what it means to FEAR.
		turret.eshot_sound = 'sound/weapons/lasercannonfire.ogg'
	src << "<span class='notice'>Turrets upgraded.</span>"

/datum/AI_Module/large/lockdown
	module_name = "Hostile Station Lockdown"
	mod_pick_name = "lockdown"
	description = "Overload the airlock, blast door and fire control networks, locking them down. Caution! This command also electrifies all airlocks. The networks will automatically reset after 90 seconds."
	cost = 30
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/lockdown

/mob/living/silicon/ai/proc/lockdown()
	set category = "Malfunction"
	set name = "Initiate Hostile Lockdown"

	if(!canUseTopic())
		return

	var/obj/machinery/door/airlock/AL
	for(var/obj/machinery/door/D in airlocks)
		if(D.z != ZLEVEL_STATION && D.z != ZLEVEL_MINING)
			continue
		spawn()
			if(istype(D, /obj/machinery/door/airlock))
				AL = D
				if(AL.canAIControl() && !AL.stat) //Must be powered and have working AI wire.
					AL.locked = 0 //For airlocks that were bolted open.
					AL.safe = 0 //DOOR CRUSH
					AL.close()
					AL.bolt() //Bolt it!
					AL.secondsElectrified = -1  //Shock it!
			else if(!D.stat) //So that only powered doors are closed.
				D.close() //Close ALL the doors!

	var/obj/machinery/computer/communications/C = locate() in machines
	if(C)
		C.post_status("alert", "lockdown")

	verbs -= /mob/living/silicon/ai/proc/lockdown
	minor_announce("Hostile runtime detected in door controllers. Isolation Lockdown protocols are now in effect. Please remain calm.","Network Alert:", 1)
	src << "<span class = 'warning'>Lockdown Initiated. Network reset in 90 seconds.</span>"
	spawn(900) //90 Seconds.
		disablelockdown() //Reset the lockdown after 90 seconds.

/mob/living/silicon/ai/proc/disablelockdown()
	set category = "Malfunction"
	set name = "Disable Lockdown"

	var/obj/machinery/door/airlock/AL
	for(var/obj/machinery/door/D in airlocks)
		spawn()
			if(istype(D, /obj/machinery/door/airlock))
				AL = D
				if(AL.canAIControl() && !AL.stat) //Must be powered and have working AI wire.
					AL.unbolt()
					AL.secondsElectrified = 0
					AL.open()
					AL.safe = 1
			else if(!D.stat) //Opens only powered doors.
				D.open() //Open everything!

	minor_announce("Automatic system reboot complete. Have a secure day.","Network reset:")

/datum/AI_Module/large/destroy_rcd
	module_name = "Destroy RCDs"
	mod_pick_name = "rcd"
	description = "Send a specialised pulse to detonate all hand-held and exosuit Rapid Cconstruction Devices on the station."
	cost = 25
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/disable_rcd

/mob/living/silicon/ai/proc/disable_rcd()
	set category = "Malfunction"
	set name = "Destroy RCDs"
	set desc = "Detonate all RCDs on the station, while sparing onboard cyborg RCDs."

	if(!canUseTopic() || malf_cooldown)
		return

	for(var/obj/item/RCD in rcd_list)
		if(!istype(RCD, /obj/item/weapon/rcd/borg)) //Ensures that cyborg RCDs are spared.
			RCD.audible_message("<span class='danger'><b>[RCD] begins to vibrate and buzz loudly!</b></span>","<span class='danger'><b>[RCD] begins vibrating violently!</b></span>")
			spawn(50) //5 seconds to get rid of it!
				if(RCD) //Make sure it still exists (In case of chain-reaction)
					explosion(RCD, 0, 0, 3, 1, flame_range = 1)
					qdel(RCD)

	src << "<span class='warning'>RCD detonation pulse emitted.</span>"
	malf_cooldown = 1
	spawn(100)
		malf_cooldown = 0

/datum/AI_Module/large/mecha_domination
	module_name = "Viral Mech Domination"
	mod_pick_name = "mechjack"
	description = "Hack into a mech's onboard computer, shunting all processes into it and ejecting any occupants. Once uploaded to the mech, it is impossible to leave.\
	Do not allow the mech to leave the station's vicinity or allow it to be destroyed."
	cost = 30
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/mech_takeover

/mob/living/silicon/ai/proc/mech_takeover()
	set name = "Compile Mecha Virus"
	set category = "Malfunction"
	set desc = "Target a mech by clicking it. Click the appropriate command when ready."
	if(stat)
		return
	can_dominate_mechs = 1 //Yep. This is all it does. Honk!
	src << "Virus package compiled. Select a target mech at any time. <b>You must remain on the station at all times. Loss of signal will result in total system lockout.</b>"
	verbs -= /mob/living/silicon/ai/proc/mech_takeover


/datum/AI_Module/large/break_fire_alarms
	module_name = "Thermal Sensor Override"
	mod_pick_name = "burnpigs"
	description = "Gives you the ability to override the thermal sensors on all fire alarms. This will remove their ability to scan for fire and thus their ability to alert. \
	Anyone can check the fire alarm's interface and may be tipped off by its status."
	one_time = 1
	cost = 25

	power_type = /mob/living/silicon/ai/proc/break_fire_alarms

/mob/living/silicon/ai/proc/break_fire_alarms()
	set name = "Override Thermal Sensors"
	set category = "Malfunction"

	if(!canUseTopic())
		return

	for(var/obj/machinery/firealarm/F in machines)
		if(F.z != ZLEVEL_STATION)
			continue
		F.emagged = 1
	src << "<span class='notice'>All thermal sensors on the station have been disabled. Fire alerts will no longer be recognized.</span>"
	src.verbs -= /mob/living/silicon/ai/proc/break_fire_alarms

/datum/AI_Module/large/break_air_alarms
	module_name = "Air Alarm Safety Override"
	mod_pick_name = "allow_flooding"
	description = "Gives you the ability to disable safeties on all air alarms. This will allow you to use the environmental mode Flood, which disables scrubbers as well as pressure checks on vents. \
	Anyone can check the air alarm's interface and may be tipped off by their nonfunctionality."
	one_time = 1
	cost = 50

	power_type = /mob/living/silicon/ai/proc/break_air_alarms

/mob/living/silicon/ai/proc/break_air_alarms()
	set name = "Disable Air Alarm Safeties"
	set category = "Malfunction"

	if(!canUseTopic())
		return

	for(var/obj/machinery/airalarm/AA in machines)
		if(AA.z != ZLEVEL_STATION)
			continue
		AA.emagged = 1
	src << "<span class='notice'>All air alarm safeties on the station have been overriden. Air alarms may now use the Flood environmental mode."
	src.verbs -= /mob/living/silicon/ai/proc/break_air_alarms



/datum/AI_Module/small/overload_machine
	module_name = "Machine Overload"
	mod_pick_name = "overload"
	description = "Overloads an electrical machine, causing a small explosion. 2 uses."
	uses = 2
	cost = 20

	power_type = /mob/living/silicon/ai/proc/overload_machine

/mob/living/silicon/ai/proc/overload_machine(obj/machinery/M in machines)
	set name = "Overload Machine"
	set category = "Malfunction"

	if(!canUseTopic())
		return

	if (istype(M, /obj/machinery))
		for(var/datum/AI_Module/small/overload_machine/overload in current_modules)
			if(overload.uses > 0)
				overload.uses --
				audible_message("<span class='italics'>You hear a loud electrical buzzing sound!</span>")
				src << "<span class='warning'>Overloading machine circuitry...</span>"
				spawn(50)
					if(M)
						explosion(get_turf(M), 0,1,1,0)
						qdel(M)
			else src << "<span class='notice'>Out of uses.</span>"
	else src << "<span class='notice'>That's not a machine.</span>"

/datum/AI_Module/small/override_machine
	module_name = "Machine Override"
	mod_pick_name = "override"
	description = "Overrides a machine's programming, causing it to rise up and attack everyone except other machines. 4 uses."
	uses = 4
	cost = 30

	power_type = /mob/living/silicon/ai/proc/override_machine


/mob/living/silicon/ai/proc/override_machine(obj/machinery/M in machines)
	set name = "Override Machine"
	set category = "Malfunction"

	if(!canUseTopic())
		return

	if (istype(M, /obj/machinery))
		if(!M.can_be_overridden())
			src << "Can't override this device."
		for(var/datum/AI_Module/small/override_machine/override in current_modules)
			if(override.uses > 0)
				override.uses --
				audible_message("<span class='italics'>You hear a loud electrical buzzing sound!</span>")
				src << "<span class='warning'>Reprogramming machine behaviour...</span>"
				spawn(50)
					if(M && !M.gc_destroyed)
						new /mob/living/simple_animal/hostile/mimic/copy/machine(get_turf(M), M, src, 1)
			else src << "<span class='notice'>Out of uses.</span>"
	else src << "<span class='notice'>That's not a machine.</span>"

/datum/AI_Module/large/place_cyborg_transformer
	module_name = "Robotic Factory (Removes Shunting)"
	mod_pick_name = "cyborgtransformer"
	description = "Build a machine anywhere, using expensive nanomachines, that can convert a living human into a loyal cyborg slave when placed inside."
	cost = 100
	power_type = /mob/living/silicon/ai/proc/place_transformer
	var/list/turfOverlays = list()

/datum/AI_Module/large/place_cyborg_transformer/New()
	for(var/i=0;i<3;i++)
		var/image/I = image("icon"='icons/turf/overlays.dmi')
		turfOverlays += I
	..()

/mob/living/silicon/ai/proc/place_transformer()
	set name = "Place Robotic Factory"
	set category = "Malfunction"
	if(!canPlaceTransformer())
		return
	var/sure = alert(src, "Are you sure you want to place the machine here?", "Are you sure?", "Yes", "No")
	if(sure == "Yes")
		if(!canPlaceTransformer())
			return
		var/turf/T = get_turf(eyeobj)
		new /obj/machinery/transformer/conveyor(T)
		playsound(T, 'sound/effects/phasein.ogg', 100, 1)
		var/datum/AI_Module/large/place_cyborg_transformer/PCT = locate() in current_modules
		PCT.uses --
		can_shunt = 0
		src << "<span class='warning'>You cannot shunt anymore.</span>"

/mob/living/silicon/ai/proc/canPlaceTransformer()
	if(!eyeobj || !isturf(src.loc) || !canUseTopic())
		return
	var/datum/AI_Module/large/place_cyborg_transformer/PCT = locate() in current_modules
	if(!PCT || PCT.uses < 1)
		alert(src, "Out of uses.")
		return
	var/turf/middle = get_turf(eyeobj)
	var/list/turfs = list(middle, locate(middle.x - 1, middle.y, middle.z), locate(middle.x + 1, middle.y, middle.z))
	var/alert_msg = "There isn't enough room. Make sure you are placing the machine in a clear area and on a floor."
	var/success = 1
	if(turfs.len == 3)
		for(var/n=1;n<4,n++)
			var/fail
			var/turf/T = turfs[n]
			if(!istype(T, /turf/simulated/floor))
				fail = 1
			var/datum/camerachunk/C = cameranet.getCameraChunk(T.x, T.y, T.z)
			if(!C.visibleTurfs[T])
				alert_msg = "We cannot get camera vision of this location."
				fail = 1
			for(var/atom/movable/AM in T.contents)
				if(AM.density)
					fail = 1
			var/image/I = PCT.turfOverlays[n]
			I.loc = T
			client.images += I
			if(fail)
				success = 0
				I.icon_state = "redOverlay"
			else
				I.icon_state = "greenOverlay"
			spawn(30)
				if(client && (I.loc == T))
					client.images -= I
	if(success)
		return 1
	alert(src, alert_msg)
	return

/datum/AI_Module/small/blackout
	module_name = "Blackout"
	mod_pick_name = "blackout"
	description = "Attempts to overload the lighting circuits on the station, destroying some bulbs. 3 uses."
	uses = 3
	cost = 15

	power_type = /mob/living/silicon/ai/proc/blackout

/mob/living/silicon/ai/proc/blackout()
	set category = "Malfunction"
	set name = "Blackout"

	if(!canUseTopic())
		return

	for(var/datum/AI_Module/small/blackout/blackout in current_modules)
		if(blackout.uses > 0)
			blackout.uses --
			for(var/obj/machinery/power/apc/apc in machines)
				if(prob(30*apc.overload))
					apc.overload_lighting()
				else apc.overload++
			src << "<span class='notice'>Overcurrent applied to the powernet.</span>"
		else src << "<span class='notice'>Out of uses.</span>"

/datum/AI_Module/small/reactivate_cameras
	module_name = "Reactivate Camera Network"
	mod_pick_name = "recam"
	description = "Runs a network-wide diagnostic on the camera network, resetting focus and re-routing power to failed cameras. Can be used to repair up to 30 cameras."
	uses = 30
	cost = 10
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/reactivate_cameras

/mob/living/silicon/ai/proc/reactivate_cameras()
	set name = "Reactivate Cameranet"
	set category = "Malfunction"

	if(!canUseTopic() || malf_cooldown)
		return
	var/fixedcams = 0 //Tells the AI how many cams it fixed. Stats are fun.

	for(var/datum/AI_Module/small/reactivate_cameras/camera in current_modules)
		for(var/obj/machinery/camera/C in cameranet.cameras)
			var/initial_range = initial(C.view_range) //To prevent calling the proc twice
			if(camera.uses > 0)
				if(!C.status)
					C.deactivate(src, 0) //Reactivates the camera based on status. Badly named proc.
					fixedcams++
					camera.uses--
				if(C.view_range != initial_range)
					C.view_range = initial_range //Fixes cameras with bad focus.
					camera.uses--
					fixedcams++
					//If a camera is both deactivated and has bad focus, it will cost two uses to fully fix!
			else
				src << "<span class='warning'>Out of uses.</span>"
				verbs -= /mob/living/silicon/ai/proc/reactivate_cameras //It is useless now, clean it up.
				break
	src << "<span class='notice'>Diagnostic complete! Operations completed: [fixedcams].</span>"

	malf_cooldown = 1
	spawn(30) //Lag protection
		malf_cooldown = 0

/datum/AI_Module/large/upgrade_cameras
	module_name = "Upgrade Camera Network"
	mod_pick_name = "upgradecam"
	description = "Install broad-spectrum scanning and electrical redundancy firmware to the camera network, enabling EMP-Proofing and light-amplified X-ray vision." //I <3 pointless technobabble
	//This used to have motion sensing as well, but testing quickly revealed that giving it to the whole cameranet is PURE HORROR.
	one_time = 1
	cost = 35 //Decent price for omniscience!

	power_type = /mob/living/silicon/ai/proc/upgrade_cameras

/mob/living/silicon/ai/proc/upgrade_cameras()
	set name = "Upgrade Cameranet"
	set category = "Malfunction"

	if(!canUseTopic())
		return

	var/upgradedcams = 0
	see_override = SEE_INVISIBLE_MINIMUM //Night-vision, without which X-ray would be very limited in power.

	for(var/obj/machinery/camera/C in cameranet.cameras)
		if(C.assembly)
			var/upgraded = 0

			if(!C.isXRay())
				C.upgradeXRay()
				//Update what it can see.
				cameranet.updateVisibility(C, 0)
				upgraded = 1

			if(!C.isEmpProof())
				C.upgradeEmpProof()
				upgraded = 1

			if(upgraded)
				upgradedcams++

	src << "<span class='notice'>OTA firmware distribution complete! Cameras upgraded: [upgradedcams]. Light amplification system online.</span>"
	verbs -= /mob/living/silicon/ai/proc/upgrade_cameras

/datum/module_picker
	var/temp = null
	var/processing_time = 50
	var/list/possible_modules = list()

/datum/module_picker/New()
	for(var/type in typesof(/datum/AI_Module))
		var/datum/AI_Module/AM = new type
		if(AM.power_type != null)
			src.possible_modules += AM

/datum/module_picker/proc/remove_verbs(mob/living/silicon/ai/A)

	for(var/datum/AI_Module/AM in possible_modules)
		A.verbs.Remove(AM.power_type)


/datum/module_picker/proc/use(mob/user)
	var/dat
	dat = "<B>Select use of processing time: (currently #[src.processing_time] left.)</B><BR>"
	dat += "<HR>"
	dat += "<B>Install Module:</B><BR>"
	dat += "<I>The number afterwards is the amount of processing time it consumes.</I><BR>"
	for(var/datum/AI_Module/large/module in src.possible_modules)
		dat += "<A href='byond://?src=\ref[src];[module.mod_pick_name]=1'>[module.module_name]</A><A href='byond://?src=\ref[src];showdesc=[module.mod_pick_name]'>\[?\]</A> ([module.cost])<BR>"
	for(var/datum/AI_Module/small/module in src.possible_modules)
		dat += "<A href='byond://?src=\ref[src];[module.mod_pick_name]=1'>[module.module_name]</A><A href='byond://?src=\ref[src];showdesc=[module.mod_pick_name]'>\[?\]</A> ([module.cost])<BR>"
	dat += "<HR>"
	if (src.temp)
		dat += "[src.temp]"
	var/datum/browser/popup = new(user, "modpicker", "Malf Module Menu")
	popup.set_content(dat)
	popup.open()
	return

/datum/module_picker/Topic(href, href_list)
	..()

	if(!isAI(usr))
		return
	var/mob/living/silicon/ai/A = usr

	if(A.stat == DEAD)
		A <<"You are already dead!" //Omae Wa Mou Shindeiru
		return

	for(var/datum/AI_Module/AM in possible_modules)
		if (href_list[AM.mod_pick_name])

			// Cost check
			if(AM.cost > src.processing_time)
				temp = "You cannot afford this module."
				break

			// Add new uses if we can, and it is allowed.
			var/datum/AI_Module/already_AM = locate(AM.type) in A.current_modules
			if(already_AM)
				if(!AM.one_time)
					already_AM.uses += AM.uses
					src.processing_time -= AM.cost
					temp = "Additional use added to [already_AM.module_name]"
					break
				else
					temp = "This module is only needed once."
					break

			// Give the power and take away the money.
			A.view_core() //A BYOND bug requires you to be viewing your core before your verbs update
			A.verbs += AM.power_type
			A.current_modules += new AM.type
			temp = AM.description
			src.processing_time -= AM.cost

		if(href_list["showdesc"])
			if(AM.mod_pick_name == href_list["showdesc"])
				temp = AM.description
	src.use(usr)
	return


/datum/AI_Module/large/eavesdrop
	module_name = "Enhanced Surveillance"
	mod_pick_name = "eavesdrop"
	description = "Via a combination of hidden microphones and lip reading software, you are able to use your cameras to listen in on conversations."
	cost = 30
	one_time = 1

	power_type = /mob/living/silicon/ai/proc/surveillance

/mob/living/silicon/ai/proc/surveillance()
	set category = "Malfunction"
	set name = "Enhanced Surveillance"

	if(eyeobj)
		eyeobj.relay_speech = TRUE
	src << "<span class='notice'>OTA firmware distribution complete! Cameras upgraded: Enhanced surveillance package online.</span>"
	verbs -= /mob/living/silicon/ai/proc/surveillance
