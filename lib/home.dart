import 'package:flutter/material.dart';
import 'admin_login.dart';
import 'login.dart';
import 'package:url_launcher/url_launcher.dart';



class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/jobsearch.png',
              height: 400,
              width: 400,
              ),
              const Text(
                'Welcome to Jobvarse BD',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Discover. Apply. Succeed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                    color: Colors.black
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Looking for Jobs',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminLoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Looking for Employee',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),

              const SizedBox(height: 20),
              const Text(
                'Contact Us:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text('Email: support@jobvarse.com'),
                    onPressed: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@jobvarse.com',
                        query: 'subject=Support Request&body=Hello Jobvarse Team,',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        throw 'Could not launch email app';
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Call: +8801234567890'),
                    onPressed: () async {
                      final Uri phoneUri = Uri(scheme: 'tel', path: '+8801234567890');
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      } else {
                        throw 'Could not launch dialer';
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.language),
                    label: const Text('Website: jobvarse_BD.com'),
                    onPressed: () async {
                      final Uri websiteUri = Uri.parse('https://www.jobvarse_BD.com');
                      if (await canLaunchUrl(websiteUri)) {
                        await launchUrl(websiteUri);
                      } else {
                        throw 'Could not launch website';
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
