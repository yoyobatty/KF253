//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFConsole extends ExtendedConsole;

state SpeechMenuVisible
{
  	function class<KFVoicePack> GetKFVoiceClass()
	{
		if(ViewportOwner == None || ViewportOwner.Actor == None || ViewportOwner.Actor.PlayerReplicationInfo == None)
			return None;

		return class<KFVoicePack>(ViewportOwner.Actor.PlayerReplicationInfo.VoiceType);
	}

    // Rebuild the array of options based on the state we are now in.
	function RebuildSMArray()
	{
		local int i; //, index;
		local class<KFVoicePack> kfvp;
		//local GameReplicationInfo GRI;
		local PlayerReplicationInfo MyPRI;
		local VoiceChatReplicationInfo VRI;
		local UnrealPlayer up;
		//local name GameMesgGroup;
		local Pawn TauntPawn;
		local bool bShowJoin, bShowLeave, bShowTalk;

		SMArraySize = 0;
		SMOffset=0;

		kfvp = GetKFVoiceClass();
		if(kfvp == None)
			return;

		//Log("TVP:"$tvp$" NumTaunts:"$tvp.Default.numTaunts);
		switch (SMState)
		{
		case SMS_Main:
			if ( VoiceChatAllowed() )
			{
				SMNameArray[SMArraySize] = SMStateName[1];
				SMIndexArray[SMArraySize] = 1;
				SMArraySize++;
			}

			if ( ViewportOwner.Actor.PlayerReplicationInfo != None && !ViewportOwner.Actor.PlayerReplicationInfo.bOnlySpectator )
			{
				for(i=2; i<9; i++)
				{
					SMNameArray[SMArraySize] = SMStateName[i];
					SMIndexArray[SMArraySize] = i;
					SMArraySize++;
				}
				if ( (ViewportOwner.Actor.Pawn != None) )
				{
					SMNameArray[SMArraySize] = SMStateName[9];
					SMIndexArray[SMArraySize] = 9;
					SMArraySize++;
				}
			}

			if ( SMArraySize == 0 )
				GotoState('');

			break;
        /*
        case SMS_PlayerSelect:
			if(ViewportOwner == None || ViewportOwner.Actor == None || ViewportOwner.Actor.PlayerReplicationInfo == None)
				return;

			GRI = ViewportOwner.Actor.GameReplicationInfo;
			MyPRI = ViewportOwner.Actor.PlayerReplicationInfo;

			// First entry is to send to 'all'
			// HACK: Don't let you send 'Hold This Position' to all all bots
			if( SMIndex != 1)
			{
				SMNameArray[SMArraySize] = SMAllString;
				SMArraySize++;
			}

			for(i=0; i<GRI.PRIArray.Length; i++)
			{
				if ( GRI.bTeamGame )
				{
					// Dont put player on list if myself, not on a team, on the same team, or a spectator.
					if( GRI.PRIArray[i].Team == None || MyPRI.Team == None )
						continue;

					if( GRI.PRIArray[i].Team.TeamIndex != MyPRI.Team.TeamIndex )
						continue;
				}

				if( GRI.PRIArray[i].TeamId == MyPRI.TeamId )
					continue;

				if( GRI.PRIArray[i].bOnlySpectator )
					continue;

				SMNameArray[SMArraySize] = GRI.PRIArray[i].PlayerName;
				SMArraySize++;
				// Dont need a number- we use the name direct
			}

			break;
            */
		case SMS_TauntAnim:
			if(ViewportOwner == None || ViewportOwner.Actor == None)
				return;

			up = UnrealPlayer(ViewportOwner.Actor);
			if(up == None || up.Pawn == None)
				return;

			TauntPawn = up.Pawn;

			for(i=0; i<TauntPawn.TauntAnims.Length; i++)
			{
				SMNameArray[SMArraySize] = TauntPawn.TauntAnimNames[Clamp(i,0,15)];  // clamped because taunt array is max 8, see Pawn.uc
				SMIndexArray[SMArraySize] = i;
				SMArraySize++;
			}

			SortSMArray();
			break;

		case SMS_VoiceChat:
			if(	ViewportOwner == None || ViewportOwner.Actor == None ||
				ViewportOwner.Actor.PlayerReplicationInfo == None || ViewportOwner.Actor.VoiceReplicationInfo == None)
			{
				log("VoiceChatChannel not displaying.  ViewportOwner:"$ViewportOwner@"Actor:"$ViewportOwner.Actor@"MyPRI:"$ViewportOwner.Actor.PlayerReplicationInfo@"VRI:"$ViewportOwner.Actor.VoiceReplicationInfo,'VoiceChat');
				return;
			}

			VRI = ViewportOwner.Actor.VoiceReplicationInfo;
			MyPRI = ViewportOwner.Actor.PlayerReplicationInfo;

			VoiceChannels = VRI.GetChannels();
			for ( i = 0; i < VoiceChannels.Length; i++ )
			{
				if ( VoiceChannels[i].CanJoinChannel(MyPRI) )
				{
					bShowTalk = True;
					if ( VoiceChannels[i].IsMember(MyPRI, True) )
						bShowLeave = True;
					else bShowJoin = True;
				}
			}

			// Only display talk option if there are any channels that we can talk in.
			if ( bShowTalk )
			{
				// Store the currently selected channel name
				SMNameArray[SMArraySize] = SMChannelOptions[2]; // Talk
				SMIndexArray[SMArraySize] = 2;
				SMArraySize++;
			}

			// Only display join option if there are any channels that we can join
			if ( bShowJoin )
			{
				SMNameArray[SMArraySize] = SMChannelOptions[0];	// Join
				SMIndexArray[SMArraySize] = 0;
				SMArraySize++;
			}

			// Only display leave option if we are a member of any channels
			if ( bShowLeave )
			{
				SMNameArray[SMArraySize] = SMChannelOptions[1];	// Leave
				SMIndexArray[SMArraySize] = 1;
				SMArraySize++;
			}

			break;

		case SMS_VoiceChatChannel:
			if(	ViewportOwner == None || ViewportOwner.Actor == None ||
				ViewportOwner.Actor.VoiceReplicationInfo == None)
			{
				log(Name@"No VoiceReplicationInfo so not generating VoiceChat menu",'VoiceChat');
				return;
			}

			VRI = ViewportOwner.Actor.VoiceReplicationInfo;
			MyPRI = ViewportOwner.Actor.PlayerReplicationInfo;
			SMStateName[ESpeechMenuState.EnumCount - 1] = SMChannelOptions[SMIndex];

			switch ( SMIndex )
			{
			case 0:    // Join
				VoiceChannels = VRI.GetChannels();
				for ( i = 0; i < VoiceChannels.Length; i++ )
				{
					if ( VoiceChannels[i].CanJoinChannel(MyPRI) && !VoiceChannels[i].IsMember(MyPRI, True) )
					{
						SMNameArray[SMArraySize] = VoiceChannels[i].GetTitle();
						SMIndexArray[SMArraySize] = VoiceChannels[i].ChannelIndex;
						SMArraySize++;
					}
				}
				break;

			case 1:    // Leave
				VoiceChannels = VRI.GetChannels();
				for ( i = 0; i < VoiceChannels.Length; i++ )
				{
					if ( VoiceChannels[i].CanJoinChannel(MyPRI) && VoiceChannels[i].IsMember(MyPRI, True) )
					{
						SMNameArray[SMArraySize] = VoiceChannels[i].GetTitle();
						SMIndexArray[SMArraySize] = VoiceChannels[i].ChannelIndex;
						SMArraySize++;
					}
				}
				break;

			case 2:    // Talk
				VoiceChannels = VRI.GetChannels();
				for ( i = 0; i < VoiceChannels.Length; i++ )
				{
					if ( VoiceChannels[i].CanJoinChannel(MyPRI) )
					{
						SMNameArray[SMArraySize] = VoiceChannels[i].GetTitle();
						SMIndexArray[SMArraySize] = VoiceChannels[i].ChannelIndex;
						SMArraySize++;
					}
				}

				break;

			}
			break;

        }
	}

    function HandleInput(int keyIn)
	{
		local int selectIndex;
		local UnrealPlayer up;
		local Pawn TauntPawn;
		local VoiceChatReplicationInfo VRI;

		// GO BACK - previous state (might back out of menu);
		if(keyIn == -1)
		{
			HighlightRow = 0;
			LeaveState();
			return;
		}

		// TOP LEVEL - we just enter a new state
		if(SMState == SMS_Main)
		{
			switch( SMNameArray[keyIn-1] )
			{
			case SMStateName[1]:
              SMType = '';
              if ( VoiceChatAllowed() )
                EnterState( SMS_VoiceChat );
                break;
			case SMStateName[2]: SMType = 'SUPP'; break; //EnterState(SMS_Ack); break;
			case SMStateName[3]: SMType = 'FORM'; break; //EnterState(SMS_FriendFire); break;
			case SMStateName[4]: SMType = 'TAKE'; break; //EnterState(SMS_Order); break;
			case SMStateName[5]: SMType = 'TRAD'; break; //EnterState(SMS_Other); break;
			case SMStateName[6]: SMType = 'MEDIC'; break; //EnterState(SMS_Taunt); break;
            case SMStateName[7]: SMType = 'WELD'; break;
            case SMStateName[8]: SMType = 'COVER'; break;

            case SMStateName[9]:
              SMType = '';
              EnterState(SMS_TauntAnim);
              break;
			}

            if(SMType!='')
            {
              ViewportOwner.Actor.Speech(SMType, SMIndexArray[selectIndex], "");
              PlayConsoleSound(SMAcceptSound);
              CloseSpeechMenu();
            }

			return;
		}

		// Next page on the same level
		if(keyIn == 0 )
		{
			// Check there is a next page!
			if(SMArraySize - SMOffset > 9)
				SMOffset += 9;

			return;
		}

		// Previous page on the same level
		if(keyIn == -2)
		{
			SMOffset = Max(SMOffset - 9, 0);
			return;
		}

		// Otherwise - we have selected something!
		selectIndex = SMOffset + keyIn - 1;
		if(selectIndex < 0 || selectIndex >= SMArraySize) // discard - out of range selections.
			return;

		switch ( SMState )
		{
		/*
        case SMS_Order:
			SMIndex = SMIndexArray[selectIndex];
			EnterState(SMS_PlayerSelect);
			break;
        */
		case SMS_VoiceChat:
			SMIndex = SMIndexArray[selectIndex];
			EnterState(SMS_VoiceChatChannel);
			break;

		case SMS_VoiceChatChannel:
			VRI = ViewportOwner.Actor.VoiceReplicationInfo;
			if (VRI == None)
				return;

			// Perform the action selected
			switch ( SMIndex )
			{
				case 0:	// Join Channel
					ViewportOwner.Actor.Join(SMNameArray[selectIndex],"");
					break;

				case 1:	// Leave Channel
					ViewportOwner.Actor.Leave(SMNameArray[selectIndex]);
					break;

				case 2:
					ViewportOwner.Actor.Speak(SMNameArray[selectIndex]);
					break;
			}

			// Add confirmation
			PlayConsoleSound(SMAcceptSound);
			CloseSpeechMenu();
			break;

		/*
        case SMS_PlayerSelect:
			if(SMNameArray[selectIndex] == SMAllString)
				ViewportOwner.Actor.Speech(SMType, SMIndex, "");
			else
				ViewportOwner.Actor.Speech(SMType, SMIndex, SMNameArray[selectIndex]);

			PlayConsoleSound(SMAcceptSound);

			CloseSpeechMenu(); // Close menu after message
			break;
        */

		case SMS_TauntAnim:
			up = UnrealPlayer(ViewportOwner.Actor);
			TauntPawn = up.Pawn;
			up.Taunt( TauntPawn.TauntAnims[ SMIndexArray[selectIndex] ] );
			PlayConsoleSound(SMAcceptSound);
			CloseSpeechMenu();
			break;

		default:
			ViewportOwner.Actor.Speech(SMType, SMIndexArray[selectIndex], "");
			PlayConsoleSound(SMAcceptSound);
			CloseSpeechMenu();
		}
	}
}

defaultproperties
{
     SMStateName(2)="Need Support"
     SMStateName(3)="Form Up"
     SMStateName(4)="Take This"
     SMStateName(5)="Going Trading"
     SMStateName(6)="MEDIC!"
     SMStateName(7)="I'm Welding"
     SMStateName(8)="I'm Covering"
     SMStateName(9)="Taunt Anim"
     Favorites(0)=(IP="69.114.228.143",Port=7777,QueryPort=7778)
}
