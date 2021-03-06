package explorviz.server.experiment;

import java.io.*;
import java.util.*;
import java.util.Map.Entry;

import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.io.Input;

import explorviz.server.login.LoginServiceImpl;
import explorviz.server.main.Configuration;
import explorviz.server.main.FileSystemHelper;
import explorviz.server.repository.LandscapePreparer;
import explorviz.server.repository.RepositoryStorage;
import explorviz.shared.model.Landscape;

public class LandscapeReplayer {
	static String FULL_FOLDER = FileSystemHelper.getExplorVizDirectory() + File.separator
			+ "replay";

	private static final Map<String, LandscapeReplayer> replayers = new HashMap<String, LandscapeReplayer>();

	private long maxTimestamp;
	private long lastTimestamp = 0;
	private long lastActivity = 0;
	private final Kryo kryo;

	/**
	 * Attention: Instance only single threaded!
	 */
	public static LandscapeReplayer getReplayerForCurrentUser() {
		final String username = LoginServiceImpl.getCurrentUsernameStatic();

		if (replayers.get(username) == null) {
			replayers.put(username, new LandscapeReplayer());
		}

		return replayers.get(username);
	}

	private LandscapeReplayer() {
		setMaxTimestamp(0);

		kryo = RepositoryStorage.createKryoInstance();
	}

	public void setMaxTimestamp(final long maxTimestamp) {
		this.maxTimestamp = maxTimestamp;
	}

	public void reset() {
		maxTimestamp = 0;
		lastTimestamp = 0;
		lastActivity = 0;
	}

	public Landscape getCurrentLandscape() {
		final SortedMap<Long, Long> landscapeList = listAllLandscapes();

		for (final Entry<Long, Long> landscapeEntry : landscapeList.entrySet()) {
			final long key = landscapeEntry.getKey();
			if ((lastTimestamp < key) && (key <= maxTimestamp)) {
				lastTimestamp = key;
				lastActivity = landscapeEntry.getValue();
				break;
			}
		}
		if (lastTimestamp > 0) {
			return getLandscape(lastTimestamp, lastActivity);
		} else {
			final Landscape emptyLandscape = new Landscape();
			emptyLandscape.setActivities(0);
			emptyLandscape.setHash(0L);
			return emptyLandscape;
		}
	}

	public Map<Long, Long> getAvailableLandscapesForTimeshift() {
		final Map<Long, Long> result = new TreeMap<Long, Long>();
		final SortedMap<Long, Long> allLandscapes = listAllLandscapes();

		for (final Entry<Long, Long> landscapeEntry : allLandscapes.entrySet()) {
			final long key = landscapeEntry.getKey();
			if (key <= maxTimestamp) {
				result.put(landscapeEntry.getKey(), landscapeEntry.getValue());
			}
		}

		return result;
	}

	private SortedMap<Long, Long> listAllLandscapes() {
		final SortedMap<Long, Long> result = new TreeMap<Long, Long>();

		final File[] fileList = new File(FULL_FOLDER).listFiles();

		if (fileList != null) {
			for (final File file : fileList) {
				if ((file != null) && file.getName().endsWith(Configuration.MODEL_EXTENSION)) {
					final String[] split = file.getName().split("-");
					final long timestamp = Long.parseLong(split[0]);
					final long activities = Long.parseLong(split[1].split("\\.")[0]);
					result.put(timestamp, activities);
				}
			}
		}

		return result;
	}

	private Landscape getLandscape(final long timestamp, final long activity) {
		Input input = null;
		Landscape landscape = null;
		try {
			input = new Input(new FileInputStream(FULL_FOLDER + File.separator + timestamp + "-"
					+ activity + Configuration.MODEL_EXTENSION));
			landscape = kryo.readObject(input, Landscape.class);
		} catch (final FileNotFoundException e) {
			e.printStackTrace();
		} finally {
			if (input != null) {
				input.close();
			}
		}

		return LandscapePreparer.prepareLandscape(landscape);
	}

	public Landscape getLandscape(final long timestampToGet) {
		final SortedMap<Long, Long> landscapes = listAllLandscapes();

		Long modelTimestamp = null;
		Long modelActivity = null;

		for (final Entry<Long, Long> entry : landscapes.entrySet()) {
			if (entry.getKey() <= timestampToGet) {
				modelTimestamp = entry.getKey();
				modelActivity = entry.getValue();
			}
		}

		if ((modelTimestamp != null) && (modelActivity != null)) {
			return getLandscape(modelTimestamp, modelActivity);
		}

		return null;
	}
}