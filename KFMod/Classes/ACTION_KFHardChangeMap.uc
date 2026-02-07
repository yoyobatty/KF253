class ACTION_KFHardChangeMap extends ScriptedAction;

function bool InitActionFor(ScriptedController C)
{
	local PlayerController CP;

	ForEach C.AllActors(class'PlayerController',CP)
	{
		CP.ConsoleCommand("DISCONNECT");
		CP.ConsoleCommand("OPEN KF-Menu?Game=unrealgame.cinematicgame");
		return false;
	}     
}

function string GetActionString()
{
	return ActionString;
}

defaultproperties
{
	ActionString="Main menu"
}
