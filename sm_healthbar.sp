#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "2.1"

int barHealth[MAXPLAYERS+1][10];
bool shouldShow[2048];
float maxhealth[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "HealthBar",
	author = "Simon",
	description = "Shows a Healthbar above a person's head",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	CreateConVar("hb_version", PLUGIN_VERSION, "HealthBar", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	HookEvent("player_spawn", OnPlayerSpawn);
}

public void OnMapStart()
{
	for(new i = 10; i <= 100; i += 10)
	{
		char full_path_vmt[64];
		Format(full_path_vmt, sizeof(full_path_vmt), "materials/Simon/healthbar/simon_bar_%d.vmt");
		char full_path_vtf[64];
		Format(full_path_vtf, sizeof(full_path_vtf), "materials/Simon/healthbar/simon_bar_%d.vtf");
		AddFileToDownloadsTable(full_path_vmt);
		AddFileToDownloadsTable(full_path_vtf);
		PrecacheModel(full_path_vtf);
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.5, SpawnHPBars, client); 
	return Plugin_Continue;
}

public Action SpawnHPBars(Handle timer, int client){
    
	float pos[3];
	GetClientEyePosition(client, pos);
	pos[2] += 25.0;
	char sample[64] = "Simon/healthbar/simon_bar";
	int j = 10;
	for(new i = 9; i >= 0; i--)
	{
		char sprite[64];
		strcopy(sprite, 64, sample);
		char buffer[32];
		Format(buffer, 32, "_%d.vmt", j*10);
		StrCat(sprite, 64, buffer);
		int ent = AttachSprite(client, sprite, pos);
		if(ent == -1)
		{
			j--;
			continue;
        }
		else if(i == 9)
		{
			shouldShow[ent] = true;
		}
		else
		{
			shouldShow[ent] = false;
		}
		SDKHook(ent, SDKHook_SetTransmit, OnSetTransmit);
		barHealth[client][i] = ent;
		j--;
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	}
	maxhealth[client] = float(GetClientHealth(client));
}

public Action OnSetTransmit(int entity, int client)
{
	if(shouldShow[entity] && GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") != client)
		return Plugin_Continue;
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	int life;
	if(!IsPlayerAlive(victim))
	{
		life = 0;
	}
	else
	{
		life = GetClientHealth(victim);
	}
	if(life == 0)
	{
		for(new i = 0; i < 10; i++)
		{
			int ent = barHealth[victim][i];
			if(ent > MAXPLAYERS && IsValidEntity(ent))
			{
				AcceptEntityInput(ent, "Kill");
			}
		}
	}
	else
	{
		int actualSprite = RoundToCeil((float(life) / maxhealth[victim] * 10.0))-1;
		for(new i = 0; i < 10; i++)
		{
			if(i == actualSprite)
			{
				shouldShow[barHealth[victim][i]] = true;
				continue;
			}
			shouldShow[barHealth[victim][i]] = false;
		}
	}
}
    
stock int AttachSprite(int Client, char[] sprite, float Origin[3] = NULL_VECTOR)
{
	if(!IsPlayerAlive(Client)) return -1;
	char iTarget[16];
	Format(iTarget, 16, "Client%d", Client);
	DispatchKeyValue(Client, "targetname", iTarget);
	if(Origin[0] == 0.0 && Origin[1] == 0.0 && Origin[2] == 0.0){
		GetClientEyePosition(Client,Origin);
		Origin[2] += 25.0;
	}    
	int Ent = CreateEntityByName("env_sprite");
	if(!Ent) return -1;
	DispatchKeyValue(Ent, "model", sprite);
	DispatchKeyValue(Ent, "classname", "env_sprite");
	DispatchKeyValue(Ent, "spawnflags", "1");
	DispatchKeyValue(Ent, "scale", "0.1");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, Origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);
	return Ent;
}