import scrapy
import re
import time
import os


class vBulletinSpider(scrapy.Spider):
    name = "vbulletin"
    start_urls = [
        'https://www.expertlaw.com/forums/forumdisplay.php?f=143&pp=200&sort=replycount&order=desc&daysprune=-1', # Moving Violations, Parking and Traffic Tickets
        'https://www.expertlaw.com/forums/forumdisplay.php?f=100&s=&pp=200&daysprune=-1&sort=replycount&prefixid=&order=desc', # Criminal Charges
        'https://www.expertlaw.com/forums/forumdisplay.php?f=34&s=&pp=200&daysprune=-1&sort=replycount&prefixid=&order=desc', # Child Custody, Support and Visitation
        'https://www.expertlaw.com/forums/forumdisplay.php?f=95&s=&pp=200&daysprune=-1&sort=replycount&prefixid=&order=desc', # Landlord-Tenant Law
        'https://www.expertlaw.com/forums/forumdisplay.php?f=58&s=&pp=200&daysprune=-1&sort=replycount&prefixid=&order=desc', # Employment and Labor
        'https://www.expertlaw.com/forums/forumdisplay.php?f=204&s=&pp=200&daysprune=-1&sort=replycount&prefixid=&order=desc', # Real Estate Ownership and Title
        #'http://www.city-data.com/forum/texas/?pp=30&sort=replycount&order=desc&daysprune=-1', # Texas
        #'http://www.city-data.com/forum/california/?pp=30&sort=replycount&order=desc&daysprune=-1', # California
        #'http://www.city-data.com/forum/florida/?pp=30&sort=replycount&order=desc&daysprune=-1', # Florida
        #'http://www.city-data.com/forum/new-york/?pp=30&sort=replycount&order=desc&daysprune=-1', # New York
        #'http://www.city-data.com/forum/politics-other-controversies/?pp=200&sort=replycount&order=desc&daysprune=-1', # Politics and Other Controversies
        #'http://www.city-data.com/forum/general-u-s/?pp=50&sort=replycount&order=desc&daysprune=-1', # General US
    ]


    def __init__(self):
        self.data_dir = self.generate_data_dir_path()

    def generate_data_dir_path(self):
        script_dir = os.path.dirname(os.path.realpath(__file__))
        plugin_dir = script_dir.split("data_helpers",1)[0]
        model_dir = plugin_dir + '/public/tf-cnn-text/'
        timestamp = str(int(time.time()))
        return model_dir + timestamp

    def parse(self, response):
        domain = response.url.split("/")[2].split(".")[1]
        titleRaw = response.css('title::text').extract()[0].lower()
        titleNoPage = re.sub(' - (.*)', '', titleRaw)
        titleNoSpecial = re.sub('[^A-Za-z0-9 ]+', '', titleNoPage)
        titleFormatted = titleNoSpecial.replace("  ", " ").replace(" ", "-")

        if hasattr(self, 'domain'):
            label = domain
            filename = domain
        else:
            label = titleFormatted.split('-')[0]
            filename = label

        titles = response.css('a[id*="thread_title"]::text').extract()

        with open(filename, "a+") as f:
            for t in titles:
                wline = t + "\t " + label + "\n"
                f.write(wline.encode('utf-8'))

        next_page = response.css('a[title^="Next"]::attr(href)').extract()[0]
        if next_page is not None and sum(1 for line in open(filename)) <= 6000:
            next_page = response.urljoin(next_page)
            yield scrapy.Request(next_page, callback=self.parse)
        else:
            self.remove_duplicates(filename)
            self.add_to_datafile(filename)

    def remove_duplicates(self, filename):
        lines_seen = set()
        duplicates = set()

        f = open(filename, "r")
        lines = f.readlines()

        for line in lines:
            if line in lines_seen:
                duplicates.add(line)
            lines_seen.add(line)

        f.close()

        with open(filename, "w") as f:
            for line in lines:
                if line not in duplicates:
                    f.write(line)

    def add_to_datafile(self, filename):

        # write to train.txt and test.txt in DATA_DIR
        with open(filename) as f:
            train_lines = f.readlines()
            if not os.path.exists(self.data_dir):
                os.makedirs(self.data_dir)
            for i, tl in enumerate(train_lines):
                if (i <= 600):
                    open(self.data_dir + '/' 'train.txt', 'a').write(tl)
                else:
                    open(self.data_dir + '/' 'test.txt', 'a').write(tl)
