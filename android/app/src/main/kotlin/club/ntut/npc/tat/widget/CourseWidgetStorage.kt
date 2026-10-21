package club.ntut.npc.tat.widget

import android.content.Context
import android.system.Os
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class CourseWidgetStorage(context: Context) {
    companion object {
        private val FINGERPRINT_PATTERN = Regex("[0-9a-f]{64}")
    }

    private val appContext = context.applicationContext
    private val directory = File(appContext.filesDir, "course_widget")
    private val lightTemporary = File(directory, "course_table_light.png.tmp")
    private val darkTemporary = File(directory, "course_table_dark.png.tmp")
    private val fingerprintTemporary = File(directory, "fingerprint.tmp")
    private val fingerprint = File(directory, "fingerprint")

    fun readFingerprint(): String? {
        if (!fingerprint.isFile) return null
        val value = fingerprint.readText()
        if (!FINGERPRINT_PATTERN.matches(value)) return null
        return value.takeIf {
            imageFile(value, dark = false).isFile &&
                imageFile(value, dark = true).isFile
        }
    }

    @Throws(IOException::class)
    fun commitBitmaps(
        lightPng: ByteArray,
        darkPng: ByteArray,
        value: String,
    ) {
        require(lightPng.isNotEmpty()) { "lightPng must not be empty" }
        require(darkPng.isNotEmpty()) { "darkPng must not be empty" }
        require(FINGERPRINT_PATTERN.matches(value)) { "invalid fingerprint" }
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Unable to create widget storage directory")
        }

        val lightImage = imageFile(value, dark = false)
        val darkImage = imageFile(value, dark = true)
        writeDurably(lightTemporary, lightPng)
        renameReplacing(lightTemporary, lightImage)
        writeDurably(darkTemporary, darkPng)
        renameReplacing(darkTemporary, darkImage)
        writeDurably(fingerprintTemporary, value.toByteArray(Charsets.UTF_8))
        renameReplacing(fingerprintTemporary, fingerprint)

        deleteObsoleteFiles(setOf(lightImage, darkImage, fingerprint))
        CourseTableWidgetProvider.updateAll(appContext)
    }

    @Throws(IOException::class)
    fun clear() {
        var failure: IOException? = null
        for (file in directory.listFiles().orEmpty()) {
            if (!file.delete() && failure == null) {
                failure = IOException("Unable to delete ${file.name}")
            }
        }
        CourseTableWidgetProvider.updateAll(appContext)
        failure?.let { throw it }
    }

    fun imageFile(dark: Boolean): File? {
        val value = readFingerprint() ?: return null
        return imageFile(value, dark)
    }

    private fun imageFile(value: String, dark: Boolean): File {
        val variant = if (dark) "dark" else "light"
        return File(directory, "course_table_${variant}_$value.png")
    }

    private fun deleteObsoleteFiles(retained: Set<File>) {
        for (file in directory.listFiles().orEmpty()) {
            if (file !in retained && !file.delete()) {
                throw IOException("Unable to delete ${file.name}")
            }
        }
    }

    private fun writeDurably(target: File, bytes: ByteArray) {
        FileOutputStream(target).use { output ->
            output.write(bytes)
            output.flush()
            output.fd.sync()
        }
    }

    private fun renameReplacing(source: File, target: File) {
        try {
            Os.rename(source.absolutePath, target.absolutePath)
        } catch (error: Exception) {
            throw IOException("Unable to replace ${target.name}", error)
        }
    }
}
