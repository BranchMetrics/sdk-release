package com.tune.ma.inapp.model;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Rect;
import android.graphics.drawable.BitmapDrawable;
import android.util.Base64;
import android.util.DisplayMetrics;
import android.view.Gravity;
import android.view.TouchDelegate;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;

/**
 * Created by johng on 2/21/17.
 */

public class TuneCloseButton extends FrameLayout {
    private static final String CLOSE_BUTTON =
            "iVBORw0KGgoAAAANSUhEUgAAAG4AAABvCAYAAAANB/VeAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAGXRFWHR" +
            "Tb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAADVFJREFUeNrsnU9sHdUVh4fZ1VkEqQmLomCzaaCJFF" +
            "NQIoFoTNWKVqLYhEWKFORHLDUbohiqRlVTmhcoFWWBX2QqFaQYRyCRLIhsYAEqIs9EtCJShZEwf1bYYUdSy" +
            "V7EXab3N+9OOnmec8+5M3dm7jz7SE/PEPvNm/nuOfecc88996Zr164FdZZ9B8aG9I8D+mWStn5fPvfGqfk6" +
            "3/dNdQGnAA2qt+7X5pwfu6ReixooQLYV0OUNcPlAQXugTSP6fXNJl/5MgwTEmQ1wMlg3q7eGfu3y4CutqBf" +
            "gzfgG0Qtwep4CrFGPrRMgTqtXS0FcXNfgFDDAaqpXf818g1kNsL2uwNUYWLfM4T6qAFgqOG0Sp3sAWJoGjp" +
            "dpQksBpz1EANvr6jM39fUFt/dvC27ZuiXYumVL9P923rmd/P2rq6vBN0vfRj8vLl2K/vvzL792fasntAldr" +
            "j04BW1cm8Vc7vzt/bcFOxQYwMHPW7d838n3W7z0bQR04cuvIpDfXb6S9yMRGzaKNp+FgXOhZXvuvivYfc+P" +
            "I1iuQElAAuD5jz5WQC/l+aiTCt54rcApaCMamrWWwfQ99IufBz+9/76gr+97lU5cl6/8J3jnvX9EEGFaMwb" +
            "zI0XMfc7BKWgwi8dt/w5atX/fcGQOfZTzF/4ZnD03m8WUrmh4bS/B6awHtGy4l4A5BPiEgjftFTgNDSNKnK" +
            "aCSTz8m4OZgWEuwsODYxF7id8p00Y9UDg0m5Tpjb1QDJjOz9nmznff/yA4+9asrQk9reA1vACXBRo0bP++h" +
            "63nm0/+/Wmw8EXH+8s456QOIEDccecdkTNkM6+urv43mHzlVPS9yoaXC5wtNIz6w4cOBgO3bRM/mA8vfOzC" +
            "w7P2ZB+4/17x3yyogfTCxMs2gyk3vMzgbKHZaBnM4LvKm/tQAatKEOBH3u1P7hOZ0wzalwteJnA20PAAoGW" +
            "71UiWjFxM/AVkNHIJ4GHgSQCePfd2dA9Fw8sKbl4CTWoaMX9Nvf6m7VxRugDer5QWcvPgRXUfk69MSU3nUw" +
            "peq3BwChpc2lEJtOeOHWVvEiMUZtGVs1G0wJk5eODXrAWBuX/mzy9K7+sR24VaK3B6OeY1F9BwYxiVZTkdR" +
            "Tgxhw+NsfcohIcgfcimgEkMThfrfOoCGoJYmMa6aJlJ+37/1JPGqcAC3mcanmhlIbRwRmZcQHv51anI+6o7" +
            "NAiC/af/0IwGIiWA+twfj0ZOGiPwGZrSa4fC38MH9ueBBnf5T8+/WKmLX5RgIE69ccYFvCM6QZ8fnF61PiJ" +
            "x+U3QnlHQfHPzXQocLFgTE7yDjz8m+aiWtnDZwSUSx0YxufwxtLo6ITYCa2KCh2wMgnpG+iUmk9O4cc5EIr" +
            "ahXOP1BE0KD6HETj6xfkQ7g/bg9Ar2ODevmdJYL0xMritoSXiIT2kLNSaZ71pZNQ7qupkzkSbvsZfnNE6Q9" +
            "qK8TaTOBPPdXpOjEhq0bZQzkdS8hi/ci96jrSBWRRxHzXcCk9my1bgmF3hSJhJfFF94QzolgcgOYa6nTCbn" +
            "qOhsFQ9Oom1YuaZjmqmeCK5dCeb4M8RqAUwmLBcjDanGGR2SzmrxdsKuv70unRFJjLdAzPdYbWAclb2JzZv" +
            "p4BLbnIxzW5pgaQZfsBcEU4Hz+Y7IrCBpIYjtGpzGjZg8SZO2FZE0LuIBcoJF079P/DV6d20yUWCUUetGu7" +
            "MpocSectoGM+B6ERQx4kvPNyUTuFNoT+r5G++u4aEqLM1RyaJ1YZdTstc0+um5bdY5tDhhDbe5DHhJaLG4h" +
            "geL9A4xnQiu06A0zpiVpkZEXGtfBLRkzFMkvDRoRcGj/AB4mHvMq+q7tHLZgUMtv80XcQWtaHgmaEXAg9ZR" +
            "GZUH+GuM3ABOT3ykmaQKRaO6R0cZEskirGt4Emjc/O5S65CsZ5yUoW6NGzL9NgpE0wTFqq4EWXNJFbEreDb" +
            "QMEBR8OrSw6RSYXvuMZrLYStwVE7tvMN8JB4MdTOu4dlCK2JpirJUKIU3SRyMx+AGTSYsrRAUAbfLm4HtR1" +
            "FN0fBg9quGBrlIhE97+MLhwSQ4cn6jQoAiilezwHvpL03J2tb1QSiFXfQiMAqN0u4T0wW+JzfPhdxKK2Ums" +
            "WumCLGFJy3EkRbolgEtFiqMYraeXde4Ae6GbS7qIzwfoZkGP6Nx/TE4UuPwINLmNzzQopduXMHzFZpp8KMN" +
            "COOgDBo1jvoABy0lrOCZCk5N8HyGFt9fWu5SsH/wZiM4KjsfN3op6+ZQcGoL70fbf+g1tGRMZ/PsYwfFWJ4" +
            "Xd+xZYyoruEFbeM8e+5330CJwxFRwC7MXLwwyNJCpqjTBBl4YhuLPrHLV/urVVdK/4MBZhwLoblCV2MDjBC" +
            "WEVW+mvHwl3V8YYGK5MMvFynJOioQHaD6UEGZ9lmFQU8kDzxdoeSSs85cHvAv/+sTqb868NdMTxbq1BocJf" +
            "NutP7D6m4d/+SCXmdgAVzQ0xGvSZjexIERAfFd3eOF6gtZD8JYBbsk2XqvyhvNC8w3eQLbrzwPcIhnVE6mt" +
            "TRU1AHUFzSd4VKCNVsPOTWUVFca20KTeZgxvZ0X9MjM+y0WAI5uiUDlJKofpCzTEdxN/e9W4pbcb3rMKnuv" +
            "KZRE4IifJJPIjcMu2c1yZozMLNMR3EG4/drcUUXbOCWWmmXxwBK5N/Su10FeWqcwDLRaf4eE5pq1gLDDVBW" +
            "jObXROIrQpyw5YFS8DHvZJ54HmOzzKcn1jXvWfi5wT3Vp9xdazLNpcohpL2qXVBC0J77fHTpDbequAR9VQM" +
            "uudi0mvkjSXlFvKFW76BO3/g/BStGjqCzxq8DOFWO0kuHnbeU5QuOkVNN/gmQqNmaWeG8CRnfFMhZuu4RUN" +
            "zSd41M4cZmF3KT41JNReyrxpnqO0jtoMktURKQOaL/CoQc8UGrfTMiek1lGbO/CgpeXfbCpAPUjJQ3QBLSs" +
            "8l9DSzCS+B6NxM1bgcIOXiToTwd5lkcDr4x5ipx3wKacPUQrP5ap5RjOZrnG6mTNpLnPsXXbyEOMWuUUIB8" +
            "8lNMS/VLdBZnfvbLLtb0ipotRcQuWLhmfZUdwpPPQncVnqQO1s7RxAaIzfppP/EZr+sTt3RhXnuNxm2/0Qy" +
            "4CWvO6h8aPXvWjcr8s97tA2ygFjrrPS3d5+TRf0fQfG4G72UxdG85Y0sTzhQnyjKBgtuwA3Pp7F9f1g+Sht" +
            "CxX8BwwYg5xQ4JomjYM0TTEdpXXojuM6f4nrVVE1jWu6hgZPMkefmDWWMCRcTtJJoS6CgBwb8DckXYOpxqL" +
            "QNmYOPZ12VOcacNpzaZm0gOpJBW+pqFRYnWX/o/SBSoLenqkWkCpdaBm1juhJFaetqiht8FUwkB968GfpWR" +
            "K+B9pp6mDcVHCc1sV71iiTiWNLNkQfJ2poFjDJrxGS/gZZLKS9GLJ0Lzr2kshhYvGzzK53vs5rGMDUHj144" +
            "cwqwEnTMdSScwdIQVMZymQKD0foWTEdohEfcGiK2wKmL7YRnA765rKYTAi8zCoqp6qHNmY8RENiIrlTrSR1" +
            "lQ2TowKTaTocoYrKqaqhmZancIgGYyLnJCc4suC0nTWqLdT+osE7Wi/wOGjIezJlCSsB06XXRuMCPQKMRhl" +
            "t6009SQDPdU7TN0fEBE2Y9xw3OSTW4BIm07hBhGsog0MmhOfK1MrlR+2n6cxU4eIvYrZp6XVtz0hFF6J2YO" +
            "iULilirfv5qMngmjsnVQjN6phNa3AaHjTvNc50cPDgXeEEjDqeVYD7QxqLyohYQsO8Nig1kZnBaXhwVo7nh" +
            "RfHNJi066J90DIkjLnD3C2gWZ1GnAuchgd7PMrBk1ZvIXGNHKiv5/JE6SvlYO0QVHBjIAotyRM285oTcFJ4" +
            "EGRQJEs+MJ+obfHpQPfOyV3DosHX6d08KW0JmRlabnA28FBujYmcMzHd7nNVJjTK6qsBt0O4RwImHxkRYcO" +
            "ZXNCcgLOBF59evNtizQ4eKBYaEeAX3dEIZeEonaPqHukEhFXZRm5ozsBpeAjSj0h+11b7khBhhlDti/e85h" +
            "RmsHPQ0x3Ru+33sdQyOCIjClrbxfN2Bk4aKtwYkA9HtSp9GZsBxBsksJ8MRUVoaEY9RHQ3gMYDFrbvQrvyX" +
            "Bcr1xYN3JY0tHlXz9opOGmQ3m0+MZfkAViWABhMomWd5ZyGtuzyuzgHp+HhyBcsCYl7YcYAkYy2NVlFC0w0" +
            "HKUMhbFryuq8BpcAiIXYiSweHZyE3RUWHsUbMDJ6tjCNDVfzWengNLyBoFMXaN2JFlqIs2bgPFAHM7k2hVF" +
            "JhnJ+cjQgPRkIFkK9B9fluLSkcx/lriOuwjs6tOftMASvEI4NtnjBS80ZbsxpYO0ynmdp4BJzH8zncZeZjb" +
            "jJC7cvPd7PjoYEDjMzSxrYdFCilAquy3w2JUG7x1IJsErBpWjgeB4TWrJg7axVFTAvwKXMgY0sTkwJsqLDm" +
            "+my5rDagOsyoyMa4q6KYbU1sJmivcTag0sxpYA4pF/9BV9yTsNq+6JZtQRHgBzUEOOfBzIAjYt8AWcRL99B" +
            "1Rqc0MwOEP8875u5yyP/E2AAXc1Sw76s+54AAAAASUVORK5CYII=";

    private ImageButton close;
    private Activity messageActivity;

    public TuneCloseButton(Context context) {
        super(context);

        messageActivity = (Activity) context;
        close = new ImageButton(context);

        DisplayMetrics dm = getResources().getDisplayMetrics();

        // TODO: set drawable based on density
        // MDPI=160, DEFAULT=160, DENSITY_HIGH=240, DENSITY_MEDIUM=160,
        // DENSITY_TV=213, DENSITY_XHIGH=320
        /*
         * if (dm.densityDpi == DisplayMetrics.DENSITY_DEFAULT || dm.densityDpi
         * == DisplayMetrics.DENSITY_HIGH || dm.densityDpi ==
         * DisplayMetrics.DENSITY_MEDIUM || dm.densityDpi ==
         * DisplayMetrics.DENSITY_TV || dm.densityDpi ==
         * DisplayMetrics.DENSITY_XHIGH) { }
         */

        // Create the close button from base64 string and set as background
        byte[] decodedString = Base64.decode(CLOSE_BUTTON, Base64.DEFAULT);
        Bitmap decodedByte = BitmapFactory.decodeByteArray(decodedString, 0, decodedString.length);
        BitmapDrawable bd = new BitmapDrawable(getResources(), decodedByte);

        close.setBackgroundDrawable(bd);

        final float density = dm.density;

        // Convert 36dp to px
        int btnSize = (int) ((36 * density) + 0.5);
        // Convert 8dp (minimum UI space size) to px
        int marginTop = (int) ((8 * density) + 0.5);
        int marginRight = marginTop;

        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(btnSize, btnSize);
        params.gravity = Gravity.RIGHT | Gravity.TOP;
        params.setMargins(0, marginTop, marginRight, 0);
        close.setLayoutParams(params);

        close.setOnClickListener(closeListener);

        addView(close);

        // Add touch delegate to close button to expand clickable area to
        // minimum button size (48dp)
        post(new Runnable() {
            public void run() {
                final Rect delegateArea = new Rect();
                close.getHitRect(delegateArea);
                int touchPadding = (int) ((12 * density) + 0.5);
                delegateArea.top -= touchPadding;
                delegateArea.left -= touchPadding;
                delegateArea.bottom += touchPadding;
                delegateArea.right += touchPadding;

                TouchDelegate expandedArea = new TouchDelegate(delegateArea,
                        close);
                if (View.class.isInstance(close.getParent())) {
                    ((View) close.getParent()).setTouchDelegate(expandedArea);
                }
            }
        });

    }

    View.OnClickListener closeListener = new View.OnClickListener() {
        public void onClick(View v) {
            // TODO: Log a close upon clicking
            messageActivity.finish();
        }
    };
}
