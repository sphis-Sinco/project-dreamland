package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;

using StringTools;

class PlayState extends FlxState
{
	public static var CURRENT_LEVEL:String = 'earth';

	public static var SCORE:Int = 0;
	var score_text:FlxText = new FlxText(0, 0, 0, "Score: 0", 16);

	var player:FlxSprite = new FlxSprite();
	var player_offscreen_padding:Float = 16;

	var bullets_group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	var bullet_offscreen_addition:Float = 16;
	var bullets_max_onscreen:Float = 2;

	var enemies_group:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	var enemy_offscreen_padding:Float = 40;

	var level_data:LevelData;

	override public function create()
	{
		add(bullets_group);

		player.loadGraphic(FileManager.getImageFile('player'), true, 32, 32);
		player.animation.add('idle', [0]);
		player.animation.add('shoot-a2', [1, 2], 4, false);
		player.animation.add('shoot-a1', [2, 3], 4, false);
		player.animation.add('shoot-a0', [3, 3], 4, false);
		player.animation.play('idle');
		player.scale.set(2, 2);
		player.screenCenter();
		player.x -= player.width * 8;
		add(player);

		add(enemies_group);

		score_text.screenCenter(X);
		score_text.y = 16;
		add(score_text);

		SCORE = 0;

		try
		{
			level_data = Json.parse(FileManager.readFile(FileManager.getDataFile('levels/$CURRENT_LEVEL${(!CURRENT_LEVEL.endsWith('.json')) ? '.json' : ''}')));
		}
		catch (e)
		{
			// trace(e);
			level_data = {
				"difficulty": "medium",
				"author": "Sphis_Sinco",
				"assets": {
					"directory": "",

					"enemy_rare": "enemy-rare",
					"enemy_easy": "enemy-easy",
					"enemy_common": "enemy-common"
				},
				"settings": {
					"scores": {
						"enemy_rare": 125,
						"enemy_easy": 50,
						"enemy_common": 25
					},
					"chances": {
						"enemy_rare": 10,
						"enemy_easy": 85
					},
					"speed_additions": {
						"enemy_common": 0,
						"enemy_easy": -10,
						"enemy_rare": 10
					}
				}
			}
		}

		super.create();
	}

	var key_up:Bool;
	var key_down:Bool;
	var key_shoot:Bool;

	override public function update(elapsed:Float)
	{
		score_text.text = "Score: " + SCORE;

		key_up = FlxG.keys.pressed.UP;
		key_down = FlxG.keys.pressed.DOWN;
		key_shoot = FlxG.keys.justReleased.SPACE;

		if (key_up)
		{
			player.y -= 10;
			if (player.y < 0 + player_offscreen_padding)
				player.y = 0 + player_offscreen_padding;
		}
		if (key_down)
		{
			player.y += 10;
			if (player.y > FlxG.height - player.height - player_offscreen_padding)
				player.y = FlxG.height - player.height - player_offscreen_padding;
		}
		if (key_shoot && bullets_group.members.length != bullets_max_onscreen)
		{
			var new_bullet:FlxSprite = new FlxSprite();
			new_bullet.makeGraphic(24, 24, FlxColor.YELLOW);
			new_bullet.setPosition(player.x, player.y);

			player.animation.play('shoot-a${bullets_max_onscreen - bullets_group.members.length}');
			// trace(bullets_max_onscreen - bullets_group.members.length);
			
			bullets_group.add(new_bullet);
		}
		else if (bullets_group.members.length == bullets_max_onscreen)
		{
			player.animation.play('shoot-a0');
		}
		for (bullet in bullets_group.members)
		{
			try
			{
				bullet.x += bullet.width;
				if (bullet.x > FlxG.width + bullet_offscreen_addition)
				{
					bullet.destroy();
					bullets_group.members.remove(bullet);
				}
			}
			catch (e) {}
		}

		if (FlxG.random.int(0, 20) == 10)
		{
			var new_enemy:FlxSprite = new FlxSprite();
			var texturepath = FileManager.getImageFile(level_data.assets.directory + level_data.assets.enemy_common);
			new_enemy.ID = 0;

			if (FlxG.random.bool(level_data.settings.chances.enemy_rare))
			{
					texturepath = FileManager.getImageFile(level_data.assets.directory + level_data.assets.enemy_rare);
				new_enemy.ID = 2;
			}
			else if (FlxG.random.bool(level_data.settings.chances.enemy_easy))
			{
				texturepath = FileManager.getImageFile(level_data.assets.directory + level_data.assets.enemy_easy);
				new_enemy.ID = 1;
			}

			new_enemy.loadGraphic(texturepath);

			new_enemy.setPosition(FlxG.width + new_enemy.width * 2, player.y + FlxG.random.float(-60, 60));
			if (new_enemy.y < 0 + enemy_offscreen_padding)
				new_enemy.y = 0 + enemy_offscreen_padding;
			if (new_enemy.y > FlxG.height - new_enemy.height - enemy_offscreen_padding)
				new_enemy.y = FlxG.height - new_enemy.height - enemy_offscreen_padding;

			enemies_group.add(new_enemy);
		}

		for (enemy in enemies_group.members)
		{
			try
			{
				var additionalSpeed:Float = 0;

				try
				{
					switch (enemy.ID)
				{
					case 0:
						additionalSpeed += level_data.settings.speed_additions.enemy_common;
					case 1:
						additionalSpeed += level_data.settings.speed_additions.enemy_easy;
					case 2:
						additionalSpeed += level_data.settings.speed_additions.enemy_rare;
				}
				}
				catch (e)
				{
					additionalSpeed = 0;
				}
				enemy.x -= enemy.width / 6 + additionalSpeed;

				if (enemy.x < 0 - enemy.width * 2)
				{
					enemy.destroy();
					enemies_group.members.remove(enemy);
				}
				for (bullet in bullets_group.members)
				{
					if (enemy.overlaps(bullet))
					{
						switch (enemy.ID)
						{
							case 0:
								SCORE += level_data.settings.scores.enemy_common;
							case 1:
								SCORE += level_data.settings.scores.enemy_easy;
							case 2:
								SCORE += level_data.settings.scores.enemy_rare;
						}
						if (Global.HIGHSCORE < SCORE)
							score_text.color = FlxColor.LIME;

						enemy.destroy();
						enemies_group.members.remove(enemy);
						bullet.destroy();
						bullets_group.members.remove(bullet);
					}
				}
				if (enemy.overlaps(player))
					FlxG.switchState(new MenuState());
			
			}
			catch (e)
			{
				trace(e);
			}
		}

		if (player.animation.finished)
			player.animation.play('idle');

		super.update(elapsed);
	}
}
