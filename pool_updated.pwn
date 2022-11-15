//Dodati pickupove i ukloniti drugi sto.
#include <a_samp>
#include <physics>
#include <zcmd>
#include <sscanf>

#define OBJ_SLOT_POOL (0)
#define 	PoolMessage(%0,%1)			SendClientMessageEx(%0, COL_ORANGE, "POOL // "WHITE""%1)
#define 	InfoMessage(%0,%1) 			SendClientMessageEx(%0, COL_SERVER, "M:DM // "WHITE""%1)
#define 	ErrorMessage(%0,%1) 		SendClientMessageEx(%0, COL_RED, "ERROR // "WHITE""%1)

#define 	COL_SERVER				0x938BD8FF
#define 	SERVER 					"{938BD8}"

//=======================================//

#define     COL_RED                 0xE81010FF
#define     RED                     "{FF0000}"

#define 	COL_GREEN				0x349E03FF
#define 	GREEN 					"{349E03}"

#define 	COL_BLUE				0x5AB7C7FF
#define 	BLUE 					"{5AB7C7}"

#define     COL_PM                  0xf5c542FF
#define     PM                      "{f5c542}"

#define     COL_LGREEN              0x03ff46FF
#define     LGREEN                  "{03ff46}"  

//=======================================//

#define 	COL_YELLOW				0xFFFF06FF
#define 	YELLOW 					"{FFFF06}"

#define     COL_DBLUE               0x0b3f7eFF
#define     DBLUE                   "{0b3f7e}"

#define 	COL_PURP 				0xBD0DBAFF
#define 	PURP					"{BD0DBA}"

#define     COL_PINK                0xFF2DFFFF
#define     PINK                    "{FF2DFF}"

#define 	COL_ORANGE				0xFF8040FF
#define 	ORANGE 					"{FF8040}"

enum poolBall
{
	bObject,
	bExisting
}

RemoveBuildingForPlayer(playerid, 2964, 506.4844, -84.8359, 997.9375, 0.25);
RemoveBuildingForPlayer(playerid, 2964, 489.7500, -80.2109, 997.7344, 0.25);
CreateDynamic3DTextLabel("(( Exit Bar ))\n(( "WHITE"Use this pickup to go to lobby"SERVER" ))", COL_SERVER, 501.980987,-67.150199,998.757812, 50.0);
ServerPickup[9] = CreateDynamicPickup(1318, 23, 501.980987,-67.150199,998.757812, 0, 11);
//Ovo je za moj pickup lokacija za Exit Bar a za enter mi je iz lobby tako da ti nista ne znaci.
//Strpaj ova dva tamo gde uklanjas objekte ucitavas mapu kako god. Ovo su dva bilijarska stola koja su prazna u baru.

new
	PlayingPool[MAX_PLAYERS],
	bool:InBar[MAX_PLAYERS], //Ovo na Pickupu za ulaz u Bar stavi na true a na izlazu false i tjt.
	PoolCamera[MAX_PLAYERS],
	UsingChalk[MAX_PLAYERS],
	PoolScore[MAX_PLAYERS],
	Float:AimAngle[MAX_PLAYERS][2],
	AimObject,
	PoolStarted,
	bool:PoolRunning,
	Player1,
	Player2,
	NextShoot,
	PoolAimer = -1,
	PoolLastShooter = -1,
	PoolLastScore,
	PoolBall[16][poolBall],
	Text:PoolTD[4],
	Float:PoolPower,
	PoolDir;

main() { }

ResetVariables(playerid){ //Stavi ovo u svoju ne znam kako vam se zove ova funkcija tako je kod mene. Uglavnom kad se loginuje neko.
	InBar[playerid] = false;
}

public OnGameModeInit()
{
	LoadPool();
	return 1;
}

public OnGameModeExit()
{
	return 1;
}

CMD:pool(playerid)
{
    if(!InBar[playerid]) return ErrorMessage(playerid, "You have to be in bar to use this command.");
	if(PoolRunning)
	{
	    PoolMessage(playerid, "One pool game is already running, please wait...");
		return 0;
	}
	PlayingPool[playerid] = 1;
	PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
	GivePlayerWeapon(playerid, 7, 1);
	PoolScore[playerid] = 0;
	PoolRunning = true;
	RespawnPoolBalls(1);
	Player1 = playerid;
	new string[164];
	format(string, sizeof(string), ""ORANGE"%s"WHITE" has just started pool queue, type "ORANGE"/join"WHITE", to play against him!", GetName(Player1));
	sendBarMessage(string);
	return 1;
}
//==============================================================================//
CMD:join(playerid)
{
   if(!InBar[playerid]) return ErrorMessage(playerid, "You have to be in bar to use this command.");
   if(!PoolRunning)
   {
	    PoolMessage(playerid, "There are no started pool games...");
		return 0;
   }
   if(PoolStarted)
   {
	    PoolMessage(playerid, "Pool table is full...");
		return 0;
   }
   if(Player1 != playerid)
   {
        PlayingPool[playerid] = 1;
		PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
		GivePlayerWeapon(playerid, 7, 1);
		PoolScore[playerid] = 0;
		PoolStarted = true;
		Player2 = playerid;
		new rand = random(2);
		if(rand == 0)
		{
			NextShoot = Player1;
			new string[164];
            format(string, sizeof(string), "First shoot belongs to "ORANGE"%s"WHITE".", GetName(Player1));
	        SendPoolPlayersMessage(string);
	    }
		else if(rand == 1)
	    {
			NextShoot = Player2;
			new string[164];
            format(string, sizeof(string), "First shoot belongs to "ORANGE"%s"WHITE".", GetName(Player2));
	        SendPoolPlayersMessage(string);
    	}
		new string[164];
        format(string, sizeof(string), ""ORANGE"%s"WHITE" has just joined pool game against "ORANGE"%s"WHITE"!", GetName(Player2), GetName(Player1));
	    sendBarMessage(string);
   }
   else
   {
        return ErrorMessage(playerid, "You can not join into your pool game...");
   }
   return 1;
}
//==============================================================================//
CMD:stop(playerid)
{ 
    if(!InBar[playerid]) return ErrorMessage(playerid, "You have to be in bar to use this command.");
    if(!PlayingPool[playerid]) return ErrorMessage(playerid, "You are not in any pool game!");
    new count = GetPoolPlayersCount();
    if(count >= 1)
	{
		PlayingPool[playerid] = 0;
		PoolStarted = false;
		PoolRunning = false;
		Player2 = INVALID_PLAYER_ID;
		Player1 = INVALID_PLAYER_ID;
		NextShoot = INVALID_PLAYER_ID;
		RespawnPoolBalls();
		if(count >= 2)
		{
			PlayingPool[Player2] = 0;
		    PlayingPool[Player1] = 0;
		}
	}
    new string[164];
    format(string, sizeof(string), ""ORANGE"%s"WHITE" has just stopped his pool game!", GetName(playerid));
    sendBarMessage(string);
    return 1;
}
//==============================================================================//
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(InBar[playerid] && !PlayingPool[playerid] || InBar[playerid] && PlayingPool[playerid] && PoolAimer != playerid)
	{
        if (IsKeyJustUp(KEY_FIRE, newkeys, oldkeys)) //Levi klik koji je blokiran u baru radi trolovanja.
		{
             OnePlayAnim(playerid, "SWEET", "sweet_ass_slap", 4.0, 0, 0, 0, 0, 0); // Ass Slapping
			 //Jbg nisam tad znao bolji nacin :/
		}
	}
	if(PoolStarted && PlayingPool[playerid])
	{
		if (IsKeyJustUp(KEY_SECONDARY_ATTACK, newkeys, oldkeys)) //ENTER
		{
			if(PlayingPool[playerid] && PoolAimer != playerid && !UsingChalk[playerid])
			{
				SetTimerEx("PlayPoolSound", 1400, 0, "d", 31807);
				SetPlayerArmedWeapon(playerid, 0);
				SetPlayerAttachedObject(playerid, OBJ_SLOT_POOL, 338, 6, 0, 0.07, -0.85, 0, 0, 0);
				ApplyAnimation(playerid, "POOL", "POOL_ChalkCue",3.0,0,0,0,0,0,1);
				UsingChalk[playerid] = 1;
				SetTimerEx("RestoreWeapon", 3500, 0, "d", playerid);
			}
		}
		if (IsKeyJustUp(KEY_JUMP, newkeys, oldkeys)) //LSHIFT ILI S
		{
			if(PoolAimer == playerid)
			{
				if(PoolCamera[playerid] < 2) PoolCamera[playerid]++;
				else PoolCamera[playerid] = 0;
				new
					Float:poolrot = AimAngle[playerid][0],
					Float:Xa,
					Float:Ya,
					Float:Za,
					Float:x,
					Float:y;
				GetObjectPos(PoolBall[0][bObject], Xa, Ya, Za);
				switch(PoolCamera[playerid])
				{
					case 0:
					{
						GetXYBehindObjectInAngle(PoolBall[0][bObject], poolrot, x, y, 0.675);
						SetPlayerCameraPos(playerid, x, y, 998.86785888672+0.28);
						SetPlayerCameraLookAt(playerid, Xa, Ya, Za+0.170);
					}
					case 1:
					{
						SetPlayerCameraPos(playerid, 511.84469604492, -84.831642150879, 1001.4904174805);
						SetPlayerCameraLookAt(playerid,510.11267089844, -84.831642150879, 998.86785888672);
					}
					case 2:
					{
						SetPlayerCameraPos(playerid, 508.7971496582, -84.831642150879, 1001.4904174805);
						SetPlayerCameraLookAt(playerid,510.11267089844, -84.831642150879, 998.86785888672);
					}
				}
			}
		}
		if (IsKeyJustUp(KEY_HANDBRAKE, newkeys, oldkeys)) //DESNI KLIK
		{
		  if(NextShoot == playerid)
		  {
			if(AreAllBallsStopped())
			{
				if(PoolAimer != playerid)
				{
					if(!UsingChalk[playerid] && PoolAimer == -1 && PoolBall[0][bExisting])
					{
						new
							Float:poolrot,
							Float:X,
							Float:Y,
							Float:Z,
							Float:Xa,
							Float:Ya,
							Float:Za,
							Float:x,
							Float:y;
						GetPlayerPos(playerid, X, Y, Z);
						GetObjectPos(PoolBall[0][bObject], Xa, Ya, Za);
						if(Is2DPointInRangeOfPoint(X, Y, Xa, Ya, 1.5) && Z < 999.5)
						{
							TogglePlayerControllable(playerid, 0);
							GetAngleToXY(Xa, Ya, X, Y, poolrot);
							SetPlayerFacingAngle(playerid, poolrot);
							AimAngle[playerid][0] = poolrot;
							AimAngle[playerid][1] = poolrot;
							SetPlayerArmedWeapon(playerid, 0);
							GetXYInFrontOfPos(Xa, Ya, poolrot+180, x, y, 0.085);
							AimObject = CreateObject(3004, x, y, Za, 7.0, 0, poolrot+180);
							switch(PoolCamera[playerid])
							{
								case 0:
								{
									GetXYBehindObjectInAngle(PoolBall[0][bObject], poolrot, x, y, 0.675);
									SetPlayerCameraPos(playerid, x, y, 998.86785888672+0.28);
									SetPlayerCameraLookAt(playerid, Xa, Ya, Za+0.170);
								}
								case 1:
								{
									SetPlayerCameraPos(playerid, 511.84469604492, -84.831642150879, 1001.4904174805);
									SetPlayerCameraLookAt(playerid,510.11267089844, -84.831642150879, 998.86785888672);
								}
								case 2:
								{
									SetPlayerCameraPos(playerid, 508.7971496582, -84.831642150879, 1001.4904174805);
									SetPlayerCameraLookAt(playerid,510.11267089844, -84.831642150879, 998.86785888672);
								}
							}
							ApplyAnimation(playerid, "POOL", "POOL_Med_Start",50.0,0,0,0,1,1,1);
							PoolAimer = playerid;
							TextDrawShowForPlayer(playerid, PoolTD[0]);
							TextDrawShowForPlayer(playerid, PoolTD[1]);
							TextDrawTextSize(PoolTD[2], 501.0, 0.0);
							TextDrawShowForPlayer(playerid, PoolTD[2]);
							TextDrawShowForPlayer(playerid, PoolTD[3]);
							PoolPower = 1.0;
							PoolDir = 0;
						}
					}
				}
				else
				{
					TogglePlayerControllable(playerid, 1);
					GivePlayerWeapon(playerid, 7, 1);
					ApplyAnimation(playerid, "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0, 1);
					SetCameraBehindPlayer(playerid);
					PoolAimer = -1;
					DestroyObject(AimObject);
					TextDrawHideForPlayer(playerid, PoolTD[0]);
					TextDrawHideForPlayer(playerid, PoolTD[1]);
					TextDrawHideForPlayer(playerid, PoolTD[2]);
					TextDrawHideForPlayer(playerid, PoolTD[3]);
				}
			}
          }
		}
		if (IsKeyJustUp(KEY_FIRE, newkeys, oldkeys)) //LEVI KLIK
		{
          if(NextShoot == playerid)
		  {
			if(PoolAimer == playerid)
			{
				new
					Float:speed;
				ApplyAnimation(playerid, "POOL", "POOL_Med_Shot",3.0,0,0,0,0,0,1);
				speed = 0.4 + (PoolPower * 2.0) / 100.0;
				PHY_SetObjectVelocity(PoolBall[0][bObject], speed * floatsin(-AimAngle[playerid][0], degrees), speed * floatcos(-AimAngle[playerid][0], degrees));
				if(PoolCamera[playerid] == 0)
				{
					switch(random(2))
					{
						case 0: SetPlayerCameraPos(playerid, 511.84469604492, -84.831642150879, 1001.4904174805);
						case 1: SetPlayerCameraPos(playerid, 508.7971496582, -84.831642150879, 1001.4904174805);
					}
					SetPlayerCameraLookAt(playerid,510.11267089844, -84.831642150879, 998.86785888672);
				}
				PlayPoolSound(31810);
				PoolAimer = -1;
				DestroyObject(AimObject);
				GivePlayerWeapon(playerid, 7, 1);
				PoolLastShooter = playerid;
				PoolLastScore = 0;
				TextDrawHideForPlayer(playerid, PoolTD[0]);
				TextDrawHideForPlayer(playerid, PoolTD[1]);
				TextDrawHideForPlayer(playerid, PoolTD[2]);
				TextDrawHideForPlayer(playerid, PoolTD[3]);
				if(NextShoot == Player2)
		        {
		            NextShoot = Player1;
		            return 1;
				}
				if(NextShoot == Player1)
		        {
		            NextShoot = Player2;
		            return 1;
				}
			}
         }
		}
 	}
	return 1;
}

public PHY_OnObjectUpdate(objectid)
{
	if(PoolStarted)
	{
		for(new i; i < sizeof PoolBall; i++)
		{
			if(objectid == PoolBall[i][bObject] && PHY_IsObjectMoving(PoolBall[i][bObject]))
			{
				new
					hole = IsBallInHole(i);
				if(hole)
				{
					new
						Float:speed,
						Float:vx, Float:vy, Float:vz;
					PHY_GetObjectVelocity(PoolBall[i][bObject], vx, vy, vz);
					speed = floatsqroot(vx * vx + vy * vy) + 0.2;

					PoolBall[i][bExisting] = 0;
					PHY_DeleteObject(PoolBall[i][bObject]);

					PlayPoolSound(31803 + random(3));

					switch(hole)
					{
						case 1: MoveObject(PoolBall[i][bObject], 509.61123657,-85.79737091,998.86785889-0.25, speed);
						case 2: MoveObject(PoolBall[i][bObject], 510.67373657,-84.84423065,998.86785889-0.25, speed);
						case 3: MoveObject(PoolBall[i][bObject], 510.61914062,-83.88769531,998.86785889-0.25, speed);
						case 4: MoveObject(PoolBall[i][bObject], 509.61077881,-83.89227295,998.86785889-0.25, speed);
						case 5: MoveObject(PoolBall[i][bObject], 510.61825562,-85.80107880,998.86785889-0.25, speed);
						case 6: MoveObject(PoolBall[i][bObject], 509.55642700,-84.84602356,998.86785889-0.25, speed);
					}
					if(i == 5 && GetPoolBallsCount() > 1)
					{
					    new string[128];
		                format(string, sizeof(string), ""ORANGE"%s"WHITE", failed black ball, game is ended!", GetName(PoolLastShooter));
		                SendPoolPlayersMessage(string);
		                PoolStarted = false;
		                PoolRunning = false;
		                PoolAimer = -1;
		                Player2 = INVALID_PLAYER_ID;
	                    Player1 = INVALID_PLAYER_ID;
		                NextShoot = INVALID_PLAYER_ID;
		                RespawnPoolBalls();
		                RestoreCamera(PoolLastShooter);
		                PoolLastShooter = -1;
		                foreach (new p : Player)
		                {
			               if(PlayingPool[p])
			               {
				            PlayingPool[p] = 0;
							ResetPlayerWeapons(p);
			               }
                        }
                        return 1;						
					}
					if(i)
					{
						if(PoolLastShooter == Player1)
		                {
		                    NextShoot = Player1;
							new string[128];
							format(string, sizeof(string), ""ORANGE"%s"WHITE" has sccored ball so he will continue his move!", GetName(Player1));
							SendPoolPlayersMessage(string);
                        }
				        if(PoolLastShooter == Player2)
		                {
		                    NextShoot = Player2;
							new string[128];
							format(string, sizeof(string), ""ORANGE"%s"WHITE" has sccored ball so he will continue his move!", GetName(Player2));
							SendPoolPlayersMessage(string);
				        }
						PoolScore[PoolLastShooter] ++;
						PoolLastScore ++;
						new string[128];
						if(PoolLastScore > 0) format(string, 128, "~g~~h~+%d", PoolLastScore);
						else format(string, 128, "~r~~h~%d", PoolLastScore);
						GameTextForPlayer(PoolLastShooter, string, 100000, 4);
						PlayerPlaySound(PoolLastShooter, 1250, 0.0, 0.0, 0.0);
					}
					else
					{
						PoolScore[PoolLastShooter] --;
						PoolLastScore --;
						new string[128];
						if(PoolLastScore > 0) format(string, 128, "~g~~h~+~r~~h~%d", PoolLastScore);
						else format(string, 128, "~r~~h~%d", PoolLastScore);
						GameTextForPlayer(PoolLastShooter, string, 100000, 4);
						PlayerPlaySound(PoolLastShooter, 1250, 0.0, 0.0, 0.0);
					}
					if(GetPoolBallsCount() <= 1)
					{
						PoolStarted = false;
						PoolRunning = false;
						PoolAimer = -1;
						Player2 = INVALID_PLAYER_ID;
			            Player1 = INVALID_PLAYER_ID;
						NextShoot = INVALID_PLAYER_ID;
						new
							winscore = GetMaxPoolScore(),
							name[MAX_PLAYER_NAME];
						RespawnPoolBalls();
						RestoreCamera(PoolLastShooter);
						PoolLastShooter = -1;
						foreach (new p : Player)
						{
							if(PlayingPool[p] && PoolScore[p] == winscore)
							{
								new
									string[128];
								GetPlayerName(p, name, sizeof name);
								format(string, 128, "{FFFF45}The winner is: {EBEBEB}%s {FFFF45}with {EBEBEB}%d {FFFF45}points.", name, winscore);
								SendPoolPlayersMessage(string);
							}
						}
						foreach (new p : Player)
						{
							if(PlayingPool[p])
							{
								PlayingPool[p] = 0;
								ResetPlayerWeapons(p);
							}
						}
					}
					else if(AreAllBallsStopped())
					{
						SetTimerEx("RestoreCamera", 800, 0, "d", PoolLastShooter);
						PoolLastShooter = -1;	
					}
				}
				return 1;
			}
		}
	}
	return 1;
}

public PHY_OnObjectCollideWithObject(object1, object2)
{
	if(PoolStarted)
	{
		for(new i; i < sizeof PoolBall; i++)
		{
			if(object1 == PoolBall[i][bObject])
			{
				PlayPoolSound(31800 + random(3));
				return 1;
			}
		}
	}
	return 1;
}

public PHY_OnObjectCollideWithWall(objectid, wallid)
{
	if(PoolStarted)
	{
		for(new i; i < sizeof PoolBall; i++)
		{
			if(objectid == PoolBall[i][bObject])
			{
				PlayPoolSound(31808);
				return 1;
			}
		}
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(PoolAimer == playerid)
	{
		PoolAimer = -1;
		TextDrawHideForPlayer(playerid, PoolTD[0]);
		TextDrawHideForPlayer(playerid, PoolTD[1]);
		TextDrawHideForPlayer(playerid, PoolTD[2]);
		TextDrawHideForPlayer(playerid, PoolTD[3]);
		DestroyObject(AimObject);
	}	
	if(PlayingPool[playerid])
	{
		new
			count = GetPoolPlayersCount();
		if(count >= 1)
		{
			PlayingPool[playerid] = 0;
			PoolStarted = false;
			PoolRunning = false;
			Player2 = INVALID_PLAYER_ID;
			Player1 = INVALID_PLAYER_ID;
			NextShoot = INVALID_PLAYER_ID;
			RespawnPoolBalls();
			if(count >= 2)
			{
			    PlayingPool[Player2] = 0;
				PlayingPool[Player1] = 0;
			}
		}
	}
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	if(pickupid == ServerPickup[9]) //Exit Bar Napravi svoj pickup na izlazu iz bara i zameni ga ovde umesto ServerPickup[9] ako ga vec nemate.
	{
		if(PlayingPool[playerid])
		{
		    new count = GetPoolPlayersCount();
            if(count >= 1)
	        {
		        PlayingPool[playerid] = 0;
		        PoolStarted = false;
		        PoolRunning = false;
		        Player2 = INVALID_PLAYER_ID;
		        Player1 = INVALID_PLAYER_ID;
		        NextShoot = INVALID_PLAYER_ID;
		        RespawnPoolBalls();
		        if(count >= 2)
		        {
			        PlayingPool[Player2] = 0;
		            PlayingPool[Player1] = 0;
		        }
	        }
		}
		ResetPlayerWeapons(playerid);
	}
	else if(pickupid == ServerPickup[8])//Enter Bar - Isto ko gore samo na ulazu
	{
		InBar[playerid] = true;
		//InLobby[playerid] = false;
		//TeleportPlayer(playerid, "Bar", 501.980987 ,-69.150199 ,998.757812, 0.0, 11, 0);
		ResetPlayerWeapons(playerid);
		//InfoMessage(playerid, "You have entered bar. /drink, /pool.");
		//PickupGTC[playerid] = gettime() + 3;
	}
}

public OnPlayerDeath(playerid, killerid, reason) //Nisam koristio ovu f-ju posto je GM u baru upaljen al trebalo bi da ovako sve radi.
{
	if(PoolAimer == playerid)
	{
		PoolAimer = -1;
		TextDrawHideForPlayer(playerid, PoolTD[0]);
		TextDrawHideForPlayer(playerid, PoolTD[1]);
		TextDrawHideForPlayer(playerid, PoolTD[2]);
		TextDrawHideForPlayer(playerid, PoolTD[3]);
		DestroyObject(AimObject);
	}
	if(PlayingPool[playerid])
	{
		new count = GetPoolPlayersCount();
        if(count >= 1)
	    {
		        PlayingPool[playerid] = 0;
		        PoolStarted = false;
		        PoolRunning = false;
		        Player2 = INVALID_PLAYER_ID;
		        Player1 = INVALID_PLAYER_ID;
		        NextShoot = INVALID_PLAYER_ID;
		        RespawnPoolBalls();
		        if(count >= 2)
		        {
			        PlayingPool[Player2] = 0;
		            PlayingPool[Player1] = 0;
		        }
	    }
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	PreloadAnimLib(playerid, "POOL");

	if(PoolAimer == playerid)
	{
		PoolAimer = -1;
		TextDrawHideForPlayer(playerid, PoolTD[0]);
		TextDrawHideForPlayer(playerid, PoolTD[1]);
		TextDrawHideForPlayer(playerid, PoolTD[2]);
		TextDrawHideForPlayer(playerid, PoolTD[3]);
		DestroyObject(AimObject);
	}
	if(PlayingPool[playerid])
	{
		PlayingPool[playerid] = 0;
		new
			count = GetPoolPlayersCount();
		if(count <= 0)
		{
			PoolStarted = 0;
			RespawnPoolBalls();
		}
	}
	return 1;
}


Float:GetPointDistanceToPoint(Float:x1,Float:y1,Float:x2,Float:y2)
{
	new Float:x, Float:y;
	x = x1-x2;
	y = y1-y2;
	return floatsqroot(x*x+y*y);
}


stock GetAngleToXY(Float:X, Float:Y, Float:CurrX, Float:CurrY, &Float:angle)
{
	angle = atan2(Y-CurrY, X-CurrX);
	angle = floatsub(angle, 90.0);
	if(angle < 0.0) angle = floatadd(angle, 360.0);
}


stock GetXYInFrontOfPos(Float:xx,Float:yy,Float:a, &Float:x2, &Float:y2, Float:distance)
{
	if(a>360)
	{
		a=a-360;
	}
	xx += (distance * floatsin(-a, degrees));
	yy += (distance * floatcos(-a, degrees));
	x2=xx;
	y2=yy;
}

stock IsPointFacingPoint(Float:dOffset, Float:X, Float:Y, Float:pA, Float:pX, Float:pY)
{
	new
		Float:ang;

	if( Y > pY ) ang = (-acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);
	else if( Y < pY && X < pX ) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 450.0);
	else if( Y < pY ) ang = (acos((X - pX) / floatsqroot((X - pX)*(X - pX) + (Y - pY)*(Y - pY))) - 90.0);

	if(AngleInRangeOfAngle(-ang, pA, dOffset)) return true;

	return false;

}

stock Is2DPointInRangeOfPoint(Float:x, Float:y, Float:x2, Float:y2, Float:range)
{
	x2 -= x;
	y2 -= y;
	return ((x2 * x2) + (y2 * y2)) < (range * range);
}

stock IsObjectInSphere(objectid,Float:x,Float:y,Float:z,Float:radius2)
{
	new Float:x1,Float:y1,Float:z1,Float:tmpdis;
	GetObjectPos(objectid,x1,y1,z1);
	tmpdis = floatsqroot(floatpower(floatabs(floatsub(x,x1)),2)+ floatpower(floatabs(floatsub(y,y1)),2)+ floatpower(floatabs(floatsub(z,z1)),2));
	if(tmpdis < radius2) return 1;
	return 0;
}

GetBallModel(i)
{
	switch(i)
	{
		/*case 0: return 3003;
		case 1: return 3002;
		case 2: return 3001;
		case 3: return 2995;
		case 4: return 2996;
		case 5: return 3106;
		case 6: return 3105;
		case 7: return 3103;
		case 8: return 3001;
		case 9: return 3100;
		case 10: return 2997;
		case 11: return 3000;
		case 12: return 3102;
		case 13: return 2999;
		case 14: return 2998;
		case 15: return 3104;*/
		
		//BILIJAR KOD MOA. Samo crvene i crna.
		
		case 0: return 3003;
		case 1: return 3101;
		case 2: return 3101;
		case 3: return 3101;
		case 4: return 3101;
		case 5: return 3106;
		case 6: return 3101;
		case 7: return 3101;
		case 8: return 3101;
		case 9: return 3101;
		case 10: return 3101;
		case 11: return 3101;
		case 12: return 3101;
		case 13: return 3101;
		case 14: return 3101;
		case 15: return 3101;
	}
	return 0;
}

stock GetPoolBallsCount()
{
	new
		count;
	for(new i; i < 16; i++)
	{
		if(PoolBall[i][bExisting] || i == 0) count++;
	}
	return count;
}


stock GetMaxPoolScore()
{
	new
		scoremax = -1;
	foreach (new i : Player)
	{
		if(PlayingPool[i])
		{
			if(PoolScore[i] > scoremax)
			{
				scoremax = PoolScore[i];
			}
		}
	}
	return scoremax;
}

stock SendPoolPlayersMessage(string[])
{
	foreach (new i : Player)
	{
		if(PlayingPool[i])
		{
			SendClientMessage(i, -1, string);
		}
	}
}

stock AreAllBallsStopped()
{
	new
		Float:x, Float:y, Float:z;
	for(new i; i < 16; i++)
	{
		if(PoolBall[i][bExisting])
		{
			PHY_GetObjectVelocity(PoolBall[i][bObject], x, y, z);
			if(x != 0.0 || y != 0.0)
				return 0;
		}
	}
	return 1;
}

stock RespawnPoolBalls(init = 0)
{
	for(new i; i < 16; i++)
	{
		DestroyObject(PoolBall[i][bObject]);
		if(PoolBall[i][bExisting])
		{
			PHY_DeleteObject(PoolBall[i][bObject]);
			PoolBall[i][bExisting] = 0;
		}
	}

	if(PoolAimer != -1)
	{
		TogglePlayerControllable(PoolAimer, 1);
		ClearAnimations(PoolAimer);
		ApplyAnimation(PoolAimer, "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0);
		SetCameraBehindPlayer(PoolAimer);
		PoolAimer = -1;
		DestroyObject(AimObject);
		TextDrawHideForPlayer(PoolAimer, PoolTD[0]);
		TextDrawHideForPlayer(PoolAimer, PoolTD[1]);
		TextDrawHideForPlayer(PoolAimer, PoolTD[2]);
		TextDrawHideForPlayer(PoolAimer, PoolTD[3]);
	}

	CreateBalls();
	if(init)
	{
		for(new i; i < sizeof PoolBall; i++)
			InitBall(i);
	}
}

stock CreateBalls()
{
	/*PoolBall[0][bObject] = CreateObject(3003, 510.11218261719, -84.40771484375, 998.86785888672, 0, 0, 0); //BELA
	PoolBall[1][bObject] = CreateObject(3002, 510.10882568359, -85.166389465332, 998.86749267578, 0, 0, 0);
	PoolBall[2][bObject] = CreateObject(3101, 510.14270019531, -85.232612609863, 998.86749267578, 0, 0, 0);
	PoolBall[3][bObject] = CreateObject(2995, 510.0676574707, -85.232200622559, 998.86749267578, 0, 0, 0);
	PoolBall[4][bObject] = CreateObject(2996, 510.18600463867, -85.295257568359, 998.86749267578, 0, 0, 0);
	PoolBall[5][bObject] = CreateObject(3106, 510.11242675781, -85.297294616699, 998.86749267578, 0, 0, 0); //CRNA
	PoolBall[6][bObject] = CreateObject(3105, 510.03665161133, -85.299163818359, 998.86749267578, 0, 0, 0);
	PoolBall[7][bObject] = CreateObject(3103, 510.22308349609, -85.362342834473, 998.86749267578, 0, 0, 0);
	PoolBall[8][bObject] = CreateObject(3001, 510.14828491211, -85.365989685059, 998.86749267578, 0, 0, 0);
	PoolBall[9][bObject] = CreateObject(3100, 510.07455444336, -85.365234375, 998.86749267578, 0, 0, 0);         //KAD BUDEM DODAVAO FULL I HALF MATCHUP OVO SU OBJEKTI KUGLA
	PoolBall[10][bObject] = CreateObject(2997, 510.00054931641, -85.363563537598, 998.86749267578, 0, 0, 0);
	PoolBall[11][bObject] = CreateObject(3000, 510.25915527344, -85.431137084961, 998.86749267578, 0, 0, 0);
	PoolBall[12][bObject] = CreateObject(3102, 510.18399047852, -85.430549621582, 998.86749267578, 0, 0, 0);
	PoolBall[13][bObject] = CreateObject(2999, 510.10900878906, -85.43196105957, 998.86749267578, 0, 0, 0);
	PoolBall[14][bObject] = CreateObject(2998, 510.03570556641, -85.432624816895, 998.86749267578, 0, 0, 0);
	PoolBall[15][bObject] = CreateObject(3104, 509.96197509766, -85.427406311035, 998.86749267578, 0, 0, 0);*/
	
	//BILIJAR KOD MOA. Ima i gore jedan kod.
	
	PoolBall[0][bObject] = CreateObject(3003, 510.11218261719, -84.40771484375, 998.86785888672, 0, 0, 0); //BELA
	PoolBall[1][bObject] = CreateObject(3101, 510.10882568359, -85.166389465332, 998.86749267578, 0, 0, 0);
	PoolBall[2][bObject] = CreateObject(3101, 510.14270019531, -85.232612609863, 998.86749267578, 0, 0, 0);
	PoolBall[3][bObject] = CreateObject(3101, 510.0676574707, -85.232200622559, 998.86749267578, 0, 0, 0);
	PoolBall[4][bObject] = CreateObject(3101, 510.18600463867, -85.295257568359, 998.86749267578, 0, 0, 0);
	PoolBall[5][bObject] = CreateObject(3106, 510.11242675781, -85.297294616699, 998.86749267578, 0, 0, 0); //CRNA
	PoolBall[6][bObject] = CreateObject(3101, 510.03665161133, -85.299163818359, 998.86749267578, 0, 0, 0);
	PoolBall[7][bObject] = CreateObject(3101, 510.22308349609, -85.362342834473, 998.86749267578, 0, 0, 0);
	PoolBall[8][bObject] = CreateObject(3101, 510.14828491211, -85.365989685059, 998.86749267578, 0, 0, 0);
	PoolBall[9][bObject] = CreateObject(3101, 510.07455444336, -85.365234375, 998.86749267578, 0, 0, 0);
	PoolBall[10][bObject] = CreateObject(3101, 510.00054931641, -85.363563537598, 998.86749267578, 0, 0, 0);
	PoolBall[11][bObject] = CreateObject(3101, 510.25915527344, -85.431137084961, 998.86749267578, 0, 0, 0);
	PoolBall[12][bObject] = CreateObject(3101, 510.18399047852, -85.430549621582, 998.86749267578, 0, 0, 0);
	PoolBall[13][bObject] = CreateObject(3101, 510.10900878906, -85.43196105957, 998.86749267578, 0, 0, 0);
	PoolBall[14][bObject] = CreateObject(3101, 510.03570556641, -85.432624816895, 998.86749267578, 0, 0, 0);
	PoolBall[15][bObject] = CreateObject(3101, 509.96197509766, -85.427406311035, 998.86749267578, 0, 0, 0);
}

stock InitBall(i)
{
	PHY_InitObject(PoolBall[i][bObject], 3003, _, _, PHY_MODE_2D);
	PHY_SetObjectFriction(PoolBall[i][bObject], 0.40);
	PHY_RollObject(PoolBall[i][bObject], _, PHY_ROLLING_MODE_ADVANCED);
	PHY_SetObjectWorld(PoolBall[i][bObject], 3);
	PoolBall[i][bExisting] = 1;
}

stock LoadPool()
{
	CreateBalls();

	SetTimer("PoolTimer", 21, 1);

	PHY_SetWallWorld(PHY_CreateWall(509.627 - 0.038, -85.780 - 0.038, 510.598 + 0.038, -85.780 - 0.038), 3);
	PHY_SetWallWorld(PHY_CreateWall(510.598 + 0.038, -85.780 - 0.038, 510.598 + 0.038, -83.907 + 0.038), 3);
	PHY_SetWallWorld(PHY_CreateWall(510.598 + 0.038, -83.907 + 0.038, 509.627 - 0.038, -83.907 + 0.038), 3);
	PHY_SetWallWorld(PHY_CreateWall(509.627 - 0.038, -83.907 + 0.038, 509.627 - 0.038, -85.780 - 0.038), 3);


	PoolTD[0] = TextDrawCreate(505.000000, 260.000000, "~n~~n~");
	TextDrawBackgroundColor(PoolTD[0], 255);
	TextDrawFont(PoolTD[0], 1);
	TextDrawLetterSize(PoolTD[0], 0.500000, 0.439999);
	TextDrawColor(PoolTD[0], -1);
	TextDrawSetOutline(PoolTD[0], 0);
	TextDrawSetProportional(PoolTD[0], 1);
	TextDrawSetShadow(PoolTD[0], 1);
	TextDrawUseBox(PoolTD[0], 1);
	TextDrawBoxColor(PoolTD[0], 255);
	TextDrawTextSize(PoolTD[0], 569.000000, -10.000000);

	PoolTD[1] = TextDrawCreate(506.000000, 261.000000, "~n~~n~");
	TextDrawBackgroundColor(PoolTD[1], 255);
	TextDrawFont(PoolTD[1], 1);
	TextDrawLetterSize(PoolTD[1], 0.500000, 0.300000);
	TextDrawColor(PoolTD[1], -1);
	TextDrawSetOutline(PoolTD[1], 0);
	TextDrawSetProportional(PoolTD[1], 1);
	TextDrawSetShadow(PoolTD[1], 1);
	TextDrawUseBox(PoolTD[1], 1);
	TextDrawBoxColor(PoolTD[1], 911303167);
	TextDrawTextSize(PoolTD[1], 568.000000, 0.000000);

	PoolTD[2] = TextDrawCreate(506.000000, 261.000000, "~n~~n~");
	TextDrawBackgroundColor(PoolTD[2], 255);
	TextDrawFont(PoolTD[2], 1);
	TextDrawLetterSize(PoolTD[2], 0.500000, 0.300000);
	TextDrawColor(PoolTD[2], -1);
	TextDrawSetOutline(PoolTD[2], 0);
	TextDrawSetProportional(PoolTD[2], 1);
	TextDrawSetShadow(PoolTD[2], 1);
	TextDrawUseBox(PoolTD[2], 1);
	TextDrawBoxColor(PoolTD[2], -1949699841);
	TextDrawTextSize(PoolTD[2], 501.000000, 0.000000);

	PoolTD[3] = TextDrawCreate(503.000000, 240.000000, "Power");
	TextDrawBackgroundColor(PoolTD[3], 255);
	TextDrawFont(PoolTD[3], 2);
	TextDrawLetterSize(PoolTD[3], 0.280000, 1.699999);
	TextDrawColor(PoolTD[3], -1);
	TextDrawSetOutline(PoolTD[3], 1);
	TextDrawSetProportional(PoolTD[3], 1);
}

stock GetPoolPlayersCount()
{
	new count;
	foreach (new i : Player)
	{
		if(PlayingPool[i])
		{
			count++;
		}
	}
	return count;
}

forward PoolTimer();
public PoolTimer()
{
	if(!PoolStarted) return 0;
	if(PoolAimer != -1)
	{
		new
			playerid = PoolAimer,
			keys,
			ud,
			lr;
		GetPlayerKeys(playerid, keys, ud, lr);
		if(!(keys & KEY_FIRE))
		{
			if(lr)
			{
				new
					Float:X,
					Float:Y,
					Float:Z,
					Float:Xa,
					Float:Ya,
					Float:Za,
					Float:x,
					Float:y,
					Float:newrot,
					Float:dist;
				GetPlayerPos(playerid, X, Y ,Z);
				GetObjectPos(PoolBall[0][bObject], Xa, Ya, Za);
				newrot = AimAngle[playerid][0] + (lr > 0 ? 0.9 : -0.9);
				dist = GetPointDistanceToPoint(X, Y, Xa, Ya);
				if(AngleInRangeOfAngle(AimAngle[playerid][1], newrot, 30.0))
				{
					AimAngle[playerid][0] = newrot;
					switch(PoolCamera[playerid])
					{
						case 0:
						{
							GetXYBehindObjectInAngle(PoolBall[0][bObject], newrot, x, y, 0.675);
							SetPlayerCameraPos(playerid, x, y, 998.86785888672+0.28);
							SetPlayerCameraLookAt(playerid, Xa, Ya, Za+0.170);
						}
						case 1:
						{
							SetPlayerCameraPos(playerid, 511.84469604492, -84.831642150879, 1001.4904174805);
							SetPlayerCameraLookAt(playerid,510.11267089844, -84.831642150879, 998.86785888672);
						}
						case 2:
						{
							SetPlayerCameraPos(playerid, 508.7971496582, -84.831642150879, 1001.4904174805);
							SetPlayerCameraLookAt(playerid,510.11267089844, -84.831642150879, 998.86785888672);
						}
					}
					GetXYInFrontOfPos(Xa, Ya, newrot+180, x, y, 0.085);
					SetObjectPos(AimObject, x, y, Za);
					SetObjectRot(AimObject, 7.0, 0, AimAngle[playerid][0]+180);
					GetXYInFrontOfPos(Xa, Ya, newrot+180, X, Y, dist);
					SetPlayerPos(playerid, X, Y, Z);
					SetPlayerFacingAngle(playerid, newrot);
				}
			}
		}
		else
		{
			if(PoolDir)
				PoolPower -= 2.0;
			else
				PoolPower += 2.0;
			if(PoolPower <= 0)
			{
				PoolDir = 0;
				PoolPower = 2.0;
			}
			else if(PoolPower > 100.0)
			{
				PoolDir = 1;
				PoolPower = 98.0;
			}
			TextDrawTextSize(PoolTD[2], 501.0 + ((67.0 * PoolPower)/100.0), 0.0);
			TextDrawShowForPlayer(playerid, PoolTD[2]);
		}
	}

	if(PoolLastShooter != -1 && AreAllBallsStopped())
	{
		SetTimerEx("RestoreCamera", 800, 0, "d", PoolLastShooter);
		PoolLastShooter = -1;
	}
	return 1;
}

forward RestoreCamera(playerid);
public RestoreCamera(playerid)
{
	if(!PoolBall[0][bExisting])
	{
		DestroyObject(PoolBall[0][bObject]);
		PoolBall[0][bObject] = CreateObject(GetBallModel(0) ,510.11218261719, -84.40771484375, 998.86785888672, 0, 0, 0);
		InitBall(0);
		GameTextForPlayer(playerid, " ", 100000, 4);
	    if(PoolAimer == playerid) return 0;
	    TogglePlayerControllable(playerid, 1);
	    return SetCameraBehindPlayer(playerid);		
	}
	GameTextForPlayer(playerid, " ", 100000, 4);
	if(PoolAimer == playerid) return 0;
	TogglePlayerControllable(playerid, 1);
	return SetCameraBehindPlayer(playerid);
}

forward RestoreWeapon(playerid);
public RestoreWeapon(playerid)
{
	RemovePlayerAttachedObject(playerid, OBJ_SLOT_POOL);
	UsingChalk[playerid] = 0;
	GivePlayerWeapon(playerid, 7, 1);
	ApplyAnimation(playerid, "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0, 1);
	return 1;
}

stock IsBallInHole(i)
{
	if(IsObjectInSphere(PoolBall[i][bObject],509.61123657,-85.79737091,998.86785889,0.0825)) return 1;
	else if(IsObjectInSphere(PoolBall[i][bObject],510.67373657,-84.84423065,998.86785889,0.0825)) return 2;
	else if(IsObjectInSphere(PoolBall[i][bObject],510.61914062,-83.88769531,998.86785889,0.0825)) return 3;
	else if(IsObjectInSphere(PoolBall[i][bObject],509.61077881,-83.89227295,998.86785889,0.0825)) return 4;
	else if(IsObjectInSphere(PoolBall[i][bObject],510.61825562,-85.80107880,998.86785889,0.0825)) return 5;
	else if(IsObjectInSphere(PoolBall[i][bObject],509.55642700,-84.84602356,998.86785889,0.0825)) return 6;
	else return 0;
}

stock GetXYBehindObjectInAngle(objectid, Float:a, &Float:x2, &Float:y2, Float:distance)
{
	new Float:z;
	GetObjectPos(objectid, x2, y2, z);

	x2 += (distance * floatsin(-a+180, degrees));
	y2 += (distance * floatcos(-a+180, degrees));
}

forward PlayPoolSound(soundid);
public PlayPoolSound(soundid)
{
	foreach(new i : Player)
	{
		if(PlayingPool[i])
		{
			PlayerPlaySound(i, soundid, 0, 0, 0);
		}
	}
	return 1;
}

stock IsKeyJustDown(key, newkeys, oldkeys)
{
	if((newkeys & key) && !(oldkeys & key)) return 1;
	return 0;
}

stock IsKeyJustUp(key, newkeys, oldkeys)
{
	if(!(newkeys & key) && (oldkeys & key)) return 1;
	return 0;
}

stock PreloadAnimLib(playerid, animlib[])
{
	ApplyAnimation(playerid,animlib,"null",0.0,0,0,0,0,0);
}

stock AngleInRangeOfAngle(Float:a1, Float:a2, Float:range)
{
	a1 -= a2;
	if((a1 < range) && (a1 > -range)) return true;

	return false;
}

sendBarMessage(string[]) 
{
	new str[160];
	format(str, sizeof(str), "BAR // "WHITE"%s", string);
	foreach(new i:Player) 
		if(Spawned[i])
			if(InBar[i]) 
				SendClientMessage(i, COL_ORANGE, str); 
	return 1;
}

//==============================================================================//
SendClientMessageEx(playerid, color, const str[], {Float,_}:...) 
{
	static
		args,
		start,
		end,
		string[144];
		
	#emit LOAD.S.pri 8
	#emit STOR.pri args

	if(args > 12)
	{
		#emit ADDR.pri str
		#emit STOR.pri start

		for (end = start + (args - 12); end > start; end -= 4)
		{
			#emit LREF.pri end
			#emit PUSH.pri
		}
		#emit PUSH.S str
		#emit PUSH.C 144
		#emit PUSH.C string
		#emit PUSH.C args
		#emit SYSREQ.C format

		SendClientMessage(playerid, color, string);

		#emit LCTRL 5
		#emit SCTRL 4
		#emit RETN
	}
	return SendClientMessage(playerid, color, str);
}

GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, name, sizeof(name));
	return name;
}