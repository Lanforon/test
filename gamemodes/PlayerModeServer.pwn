#include <a_samp>
#include <fix>
#include <a_mysql>
#include <streamer>
#include <Pawn.CMD>
#include <Foreach>
#include <sscanf2>
#include <Pawn.Regex>
#include <crashdetect>


#define SQL_HOST "localhost"
#define SQL_USER "root"
#define SQL_PASS ""
#define SQL_BASE "login"

#define SPD ShowPlayerDialog
#define SCM SendClientMessage
#define SCMTA SendClientMessageToAll

#define COLOR_WHITE 0xFFFFFFF
#define COLOR_RED   0xff0000AA



//================================= Переменные =================================
//----------------------------------- Пикапы -----------------------------------
new pickups[2];
//------------------------------------------------------------------------------
//----------------------------------- Мусорка ----------------------------------
new MySQL:dbHandle;
//------------------------------------------------------------------------------
//==============================================================================
enum player_adm_command
{
	pKick = 0,
}
new player_command[MAX_PLAYERS][player_adm_command];
enum player
{
	ID,
	NAME[MAX_PLAYER_NAME],
	PASSWORD[65],
	EMAIL[65],
	REF,
	SEX,
	SKIN,
	REGDATA[13],
	IPDATA[16],
	ADMIN,
	MONEY,
	LVL,
	EXP,
	MINS,
	
}
new player_info[MAX_PLAYERS][player];
enum DIALOGS
{
	DLG_REG,
	DLG_REGEMAIL,
	DLG_REFREG,
	DLG_SEX,
	DLG_LOG,
	DLG_SETCMD,
}

main() return true;

public OnGameModeInit()
{
    DisableInteriorEnterExits();
	LoadInteriors();
	LoadPickups();
	ConnectSQL();
	return 1;
}
stock ConnectSQL()
{
	dbHandle = mysql_connect(SQL_HOST, SQL_USER, SQL_PASS, SQL_BASE);
    switch(mysql_errno())
	{
		case 0: print("[SQL]: База данных была успешно подключена");
		case 1044: print("[SQL]: Не удалось подключиться к базе данных | [Проверьте написание User]");
		case 1045: print("[SQL]: Не удалось подключиться к базе данных | [Проверьте написание Pass]");
		case 1049: print("[SQL]: Не удалось подключиться к базе данных | [Проверьте написание Base]");
		default: printf("[SQL]: Не удалось подключиться к базе данных | Ошибка: #%d", mysql_errno());
	}
	mysql_log(ERROR | WARNING);
 	return 1;
}

stock LoadInteriors()
{
	#include <interiors\Police Departament.inc>
}

stock LoadPickups()
{
    pickups[0] = CreatePickup(1318,23,1555.0691,-1675.5140,16.1953); // Пикап входа в LSPD
	pickups[1] = CreatePickup(1318,23,16.9403,1513.0972,1086.0869); // Пикап выхода с LSPD
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 0;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, player_info[playerid][NAME], MAX_PLAYER_NAME);
	static const fmt_query[] = "SELECT `password` FROM `usets` WHERE `name` = '%s'";
	new query[sizeof(fmt_query)+(-2+MAX_PLAYER_NAME)];
	format(query, sizeof(query), fmt_query, player_info[playerid][NAME]);
	mysql_tquery(dbHandle, query, "CheckRegistration", "i", playerid);
	
	TogglePlayerSpectating(playerid, 1);
	
	SetPVarInt(playerid, "WrongPassword", 3);
	return 1;
}

forward CheckRegistration(playerid);
public CheckRegistration(playerid)
{
	new rows;
	cache_get_row_count(rows);
	if(rows)
	{
	    cache_get_value_name(0, "password", player_info[playerid][PASSWORD], 64);
	    print(player_info[playerid][PASSWORD]);
	    ShowLogin(playerid);
	} 
	else ShowRegistration(playerid);
}

stock ShowLogin(playerid)
{
    new dialog[363];
	format(dialog, sizeof(dialog),
		"{FFFFFF}Уважаемый{0089ff} %s, рады снова приветствовать вас в штате Macondo Role Play!\n\
		Данный аккаунт с таким никнеймом%s {FF0000}зарегистрирован{FFFFFF} в нашем штате.\n\
		Для игры на сервере вы должны пройти авторизацию.\n\
		{FF0000}Примечание{FFFFFF}:\n\
		{FF0000}Если вы не регистрировали аккаунт, перейдите в ваш лаунчер и измените ник-нейм{FFFFFF}!",
	player_info[playerid][NAME], player_info[playerid][NAME]);
	SPD(playerid, DLG_LOG, DIALOG_STYLE_INPUT, "{ffd100}Авторизация | Пароль{FFFFFF}", dialog, "Вход", "Выход");
}

stock ShowRegistration(playerid)
{
	new dialog[373];
	format(dialog, sizeof(dialog),
		"{FFFFFF}Уважаемый{0089ff} %s, рады приветствовать вас в штате Macondo Role Play!\n\
		Аккаунт с никнеймом%s {FF0000}не зарегистрирован{FFFFFF} в нашем штате.\n\
		Для игры на сервере вы должны пройти регистрацию.\n\
		{FF0000}Примечание{FFFFFF}:\n\
		Пароль должен быть от 8-и до 32-ух символов\n\
		Пароль должен содержать только цифры и латинские символы любого регистра",
	player_info[playerid][NAME], player_info[playerid][NAME]);
	SPD(playerid, DLG_REG, DIALOG_STYLE_INPUT, "{ffd100}Регистрация | {FFFFFF}Вход", dialog, "Далее", "Выход");
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{   if(SetPVarInt(playerid, "logged") == 0)
	{
	    SCM(playerid, COLOR_RED, "[Ошибка]{FFFFFF} Для игры на сервере нужно авторизоваться!");
		Kick(playerid);
	}
	SetPlayerPos(playerid, 1760.7123,-1895.0684,13.5611);
	SetPlayerFacingAngle(playerid, 269.9680);
	SetCameraBehindPlayer(playerid);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new string[144];
 	if(strlen(text) < 113)
	{
 		format(string, sizeof(string), "%s[%d]: %s", player_info[playerid][NAME], playerid, text);
		ProxDetector(20.0, playerid, string, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE, COLOR_WHITE);
		SetPlayerChatBubble(playerid, text, COLOR_WHITE, 7500);
		if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
		{
		    ApplyAnimation(playerid, "PED", "IDLE_chat", 4.1, 0, 1, 1, 1, 1);
		    SetTimerEx("StopChatAnim", 3200, false, "d", playerid);
		}
		return 0;
 	}
	else
	{
	    SCM(playerid, COLOR_RED, "Ваше сообщение слишком длинное!");
	    return 0;
	}
	return 0;
}
forward StopChatAnim(playerid);
public StopChatAnim(playerid)
{
	ApplyAnimation(playerid, "PED", "facanger", 4.1, 0, 1, 1, 1, 1);
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    if(pickupid == pickups[0]) // вход
	{
	    SetPlayerInterior(playerid, 1);
		SetPlayerPos(playerid, 17.0409,1510.6080,1086.0869);// это само появление в интерьере после телепорта
		SetCameraBehindPlayer(playerid);
		SetPlayerFacingAngle(playerid, 175.7587);
		SetPlayerVirtualWorld(playerid, 0); //это ид виртуально мира
	}
	if(pickupid == pickups[1]) // выход
	{
		SetPlayerInterior(playerid, 0); // ид интерьера , тут 0 так как мы выходим на улицу
		SetPlayerPos(playerid, 1552.7452,-1675.5271,16.1953);//координаты телепорта
		SetCameraBehindPlayer(playerid);
		SetPlayerFacingAngle(playerid, 96.3799);
		SetPlayerVirtualWorld(playerid, 0); // ид виртуал мира ну так как выход то тогда 0 !
	}
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
        if(player_info[playerid][ADMIN] >= 4)
        {
                new vehicleid = GetPlayerVehicleID(playerid);
                if(vehicleid > 0 && GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
                {
                        SetVehiclePos(vehicleid, fX, fY, fZ);
                }
                else
                {
                        SetPlayerPos(playerid, fX, fY, fZ); 
                }
        }
        return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case DLG_REG:
		{
		    if(response)
		    {
		        if(!strlen(inputtext))
		        {
		            CheckRegistration(playerid);
		            return SCM(playerid, COLOR_RED, "[Ошибка] Введите пароль ниже и нажмите \"Далее\"");
		        }
				if(strlen(inputtext) < 8 || strlen(inputtext) > 32)
				{
				    CheckRegistration(playerid);
		            return SCM(playerid, COLOR_RED, "[Ошибка] длина пароля должна быть от 8-и до 32-ух символов!");
				}
				new regex:rg_passwordcheck = regex_new("^[a-zA-Z0-9]{1,}$");
				if(regex_check(inputtext, rg_passwordcheck))
				{
					strmid(player_info[playerid][PASSWORD], inputtext, 0, strlen(inputtext), 32);
					SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{ffd100}Регистрация | {FFFFFF}Email",
				 		"{FFFFFF}Введите ваш Email адрес в поле ниже и нажмите \"Далее\"\n\
						 {FF0000}Если вы потреяете доступ к аккаунуту, то вы сможете восстоновить его с помощью почты{FFFFFF}.",
						 "Далее", "Выход");
				}
				else
				{
                    CheckRegistration(playerid);
		            return SCM(playerid, COLOR_RED, "[Ошибка] Пароль может состоять только из цифр и латинских символов!");
				}
		    }
		    else
		    {
		        SCM(playerid, COLOR_RED, "Чтобы выйти с сервера напишите \"/q\"");
				SPD(playerid, -1, 0, " ", " ", " ", " ");
				return Kick(playerid);
		    }
		    
		}
		case DLG_REGEMAIL:
		{
			if(response)
			{
		    	if(!strlen(inputtext))
      			{
        			SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{ffd100}Регистрация | {FFFFFF}Email",
			 			"{FFFFFF}Введите ваш Email адрес в поле ниже и нажмите \"Далее\"\n\
					 	{FF0000}Если вы потреяете доступ к аккаунуту, то вы сможете восстоновить его с помощью почты{FFFFFF}.",
					 	"Далее", "Выход");
					return SCM(playerid, COLOR_RED, "[Ошибка] Введите ваш Email в поле!");
      			}
         		new regex:rg_emailcheck = regex_new("([A-Za-z0-9]{1})([A-Za-z0-9_\\.\\-]{3,30})@([a-z]{2,6})\\.([a-z]{2,4})");
	      		if(regex_check(inputtext, rg_emailcheck))
				{
					strmid(player_info[playerid][EMAIL], inputtext, 0, strlen(inputtext), 64);
					SPD(playerid, DLG_REFREG, DIALOG_STYLE_INPUT, "{ffd100}Регистрация | {FFFFFF}Рефералы",
				 		"{FFFFFF}Если вы пришли на в наш штат {FF0000}по приглашению друга{FFFFFF}\n\
						 То пожалуйста введите ник-нейм друга в поле ниже.\n\
						 По достижению 3-его уровня вы автоматически получите 15.000$ на свой игровой счет!",
						 "Далее", "Пропустить");
				}
				else
				{
				   SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{ffd100}Регистрация | {FFFFFF}Email",
			 			"{FFFFFF}Введите ваш Email адрес в поле ниже и нажмите \"Далее\"\n\
					 	{FF0000}Если вы потреяете доступ к аккаунуту, то вы сможете восстоновить его с помощью почты{FFFFFF}.",
					 	"Далее", "Выход");
				   return SCM(playerid, COLOR_RED, "{}[Ошибка] Пожалуйста введите правильно свой Email адрес!");
				}
			}
			else
		    {
		        SCM(playerid, COLOR_RED, "Чтобы выйти с сервера напишите \"/q\"");
				SPD(playerid, -1, 0, " ", " ", " ", " ");
				return Kick(playerid);
		    }
		}
		case DLG_REFREG:
		{
		    if(response)
		    {
		        if(!strlen(inputtext))
   				{
				    SPD(playerid, DLG_REGEMAIL, DIALOG_STYLE_INPUT, "{ffd100}Регистрация | {FFFFFF}Рефералы",
				 			"{FFFFFF}Если вы пришли на в наш штат {FF0000}по приглашению друга{FFFFFF}\n\
							 То пожалуйста введите ник-нейм друга в поле ниже.\n\
							 По достижению 3-его уровня вы автоматически получите 15.000$ на свой игровой счет!",
						 	"Далее", "Пропустить");
					return SCM(playerid, COLOR_RED, "[Ошибка] Введите ник друга в поле!");
     			}
		    }
		    else
		    {
				SPD(playerid, DLG_SEX, DIALOG_STYLE_MSGBOX, "{ffd100}Регистрация | {FFFFFF}Выбор пола",
					"{FFFFFF}Выберите ваш пол для проживания внашем штате.\n\
					В будущем вы сможете по желанию его сменить.",
					 "Мужской", "Женский");
		    }
		}
		case DLG_SEX:
		{
		    new male[11] = {6, 78, 79, 134, 135, 137, 160, 112, 213, 230, 239};
			new woman[7] = {65, 152, 201, 207, 218, 237, 298};

		    if(response)
			{
				player_info[playerid][SKIN] = male[random(11)];
				player_info[playerid][SEX] = 1;
			} 
		    else
			{
				player_info[playerid][SKIN] = woman[random(11)];
				player_info[playerid][SEX] = 2;
			}
		    new Year, Month, Day;
		    getdate(Year, Month, Day);
		    new date[13];
		    format(date, sizeof(date), "%02d.%02.d.%d", Day, Month, Year);
		    player_info[playerid][REGDATA] = date;
		    
		    new ip[16];
		    GetPlayerIp(playerid, ip, sizeof(ip));
		    player_info[playerid][IPDATA] = ip;
		    
		    static const fmt_query[] = "INSERT INTO `usets`(`name`, `password`, `email`, `ref`, `sex`, `skin`, `regdata`, `ipdata`) VALUES ('%s', '%s', '%s', '%d', '%d', '%d', '%s', '%s')";
			new query[sizeof(fmt_query)+(-2+MAX_PLAYER_NAME)+(-2+64)+(-2+64)+(-2+8)+(-2+1)+(-2+3)+(-2+12)+(-2+15)];
			format(query, sizeof(query), fmt_query, player_info[playerid][NAME], player_info[playerid][PASSWORD], player_info[playerid][EMAIL], player_info[playerid][REF], player_info[playerid][SEX], player_info[playerid][SKIN], player_info[playerid][REGDATA], player_info[playerid][IPDATA]);
			mysql_query(dbHandle, query);
			
			static const fmt_query2[] = "SELECT * FROM `usets` WHERE `name` = '%s' AND `password` = '%s'";
			format(query, sizeof(query), fmt_query2, player_info[playerid][NAME], player_info[playerid][PASSWORD]);
			mysql_tquery(dbHandle, query, "PlayerLogin", "i", playerid);
		}
		case DLG_LOG:
		{
		    if(response)
		    {
		        if(!strcmp(inputtext, player_info[playerid][PASSWORD], false))
		        {
              		static const fmt_query[] = "SELECT * FROM `usets` WHERE `name` = '%s' AND `password` = '%s'";
              		new query[sizeof(fmt_query)+(-2+MAX_PLAYER_NAME)+(-2+64)];
					format(query, sizeof(query), fmt_query, player_info[playerid][NAME], player_info[playerid][PASSWORD]);
					mysql_tquery(dbHandle, query, "PlayerLogin", "i", playerid);
		        }
		        else
		        {
					new string[86];
					SetPVarInt(playerid, "WrongPassword", GetPVarInt(playerid, "WrongPassword")-1);
					if(GetPVarInt(playerid, "WrongPassword") > 0)
					{
						format(string, sizeof(string), "{FF0000}[Ошибка]{FFFFFF} Вы неправильно ввели пароль, попробуйте еще раз. Попыток: %d", GetPVarInt(playerid, "WrongPassword"));
						SCM(playerid, COLOR_RED, string);
					}
					if(GetPVarInt(playerid, "WrongPassword") == 0)
					{
					    SCM(playerid, COLOR_RED, "Вы исчерпали лимит попыток ввода и были отключены от сервера.");
						Kick(playerid);
					}
		            ShowLogin(playerid);
		        }
		    }
		    else
		    {
		        SCM(playerid, COLOR_RED, "Чтобы выйти с сервера напишите \"/q\"");
				SPD(playerid, -1, 0, " ", " ", " ", " ");
				return Kick(playerid);
		    }
		}
		case 15444:
        {
            if(response)
            {
                switch(listitem)
                {
	                case 0:
                 	{
                  		if(player_command[GetPVarInt(playerid, "CmdsID")][pKick]>0)
                    	{
		                  	player_command[GetPVarInt(playerid, "CmdsID")][pKick]=0;
                  		}
                  		else
                  		{
		                  	player_command[GetPVarInt(playerid, "CmdsID")][pKick]=1;
                  		}
                  		SetCmdSettings(playerid);
		            }
				}
			}
		}
	}
}
forward PlayerLogin(playerid);
public PlayerLogin(playerid)
{
	new rows;
	cache_get_row_count(rows);
	if(rows)
	{
		cache_get_value_name_int(0, "id", player_info[playerid][ID]);
		cache_get_value_name(0, "email", player_info[playerid][EMAIL], 65);
		cache_get_value_name_int(0, "ref", player_info[playerid][REF]);
		cache_get_value_name_int(0, "sex", player_info[playerid][SEX]);
		cache_get_value_name_int(0, "skin", player_info[playerid][SKIN]);
		cache_get_value_name(0, "regdata", player_info[playerid][REGDATA], 13);
		cache_get_value_name(0, "ipdata", player_info[playerid][IPDATA], 16);
		cache_get_value_name_int(0, "admin", player_info[playerid][ADMIN]);
		
		TogglePlayerSpectating(playerid, 0);
		SetSpawnInfo(playerid, 0, SKIN, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		SpawnPlayer(playerid);
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

stock ProxDetector(Float:radi, playerid, string[],col1,col2,col3,col4,col5)
{
	if(IsPlayerConnected(playerid))
	{
		new Float:posx;new Float:posy;new Float:posz;new Float:oldposx;new Float:oldposy;new Float:oldposz;new Float:tempposx;new Float:tempposy;new Float:tempposz;
		GetPlayerPos(playerid, oldposx, oldposy, oldposz);
		foreach(new i: Player)
		{
			if(IsPlayerConnected(i))
			{
				if(GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(i))
				{
					GetPlayerPos(i, posx, posy, posz);
					tempposx = (oldposx -posx);
					tempposy = (oldposy -posy);
					tempposz = (oldposz -posz);
					if(((tempposx < radi/16) && (tempposx > -radi/16)) && ((tempposy < radi/16) && (tempposy > -radi/16)) && ((tempposz < radi/16) && (tempposz > -radi/16))) SCM(i, col1, string);
					else if(((tempposx < radi/8) && (tempposx > -radi/8)) && ((tempposy < radi/8) && (tempposy > -radi/8)) && ((tempposz < radi/8) && (tempposz > -radi/8))) SCM(i, col2, string);
					else if(((tempposx < radi/4) && (tempposx > -radi/4)) && ((tempposy < radi/4) && (tempposy > -radi/4)) && ((tempposz < radi/4) && (tempposz > -radi/4))) SCM(i, col3, string);
					else if(((tempposx < radi/2) && (tempposx > -radi/2)) && ((tempposy < radi/2) && (tempposy > -radi/2)) && ((tempposz < radi/2) && (tempposz > -radi/2))) SCM(i, col4, string);
					else if(((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi))) SCM(i, col5, string);
				}
			}
		}
	}
	return 1;
}

stock GiveMoney(playerid, money)
{
	player_info[playerid][MONEY] += money;
	static const fmt_query[] = "UPDATE `usets` SET `money` = '%d' WHERE `id` = '%d'";
	new query[sizeof(fmt_query)+(-2+9)+(-2+8)];
	format(query, sizeof(query), fmt_query, player_info[playerid][MONEY], player_info[playerid][ID]);
	mysql_query(dbHandle, query);
	GivePlayerMoney(playerid, money);
}

forward SetCmdSettings(playerid);
public SetCmdSettings(playerid)
{
    new kick[40], cfgstring[100];
    if(player_command[GetPVarInt(playerid, "CmdsID")][pKick] == 0) kick = "[Не выдано]";
    else kick = "[Выдано]";
    format(cfgstring,sizeof(cfgstring),"\
    {AFAFAF}/kick: %s", kick);
    return SPD(playerid, 15444, DIALOG_STYLE_LIST, "Выбирите команду", cfgstring, "Выбор", "Отмена");
}

CMD:kick(playerid, params[])
{
 	if(player_command[playerid][pKick] <= 0)
	{
	    return SCM(playerid, COLOR_RED, "[Ошибка]{FFFFFF} У вас нету прав на использование данной команды!");
	}
	else if(sscanf(params,"i", params[0]))
 	{
  	 	return SCM(playerid, COLOR_RED, "[Ошибка]{FFFFFF} /kick [id]");
	}
	else
	{
     	return Kick(params[0]);
	}
	return 1;
}

CMD:setcmd(playerid, params[])
{
    
	if(sscanf(params,"i", params[0]))
	{
		return SCM(playerid, COLOR_RED, "[Ошибка]{FFFFFF} /setcmd [id]");
	}
	else
	{
		SetPVarInt(playerid,"CmdsID",params[0]);
	    SetCmdSettings(playerid);
	} 
	
	return true;
}
